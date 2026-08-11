package dev.buttonooo.essential_key.unlock.routes

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log
import dev.buttonooo.essential_key.unlock.ConsumerPackages
import dev.buttonooo.essential_key.unlock.adb.AdbConnectionManager
import dev.buttonooo.essential_key.unlock.adb.PairingNotification
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeoutOrNull
import java.io.BufferedReader
import java.io.File
import kotlin.coroutines.resume

private const val PAIRING_SERVICE = "_adb-tls-pairing._tcp."
private const val CONNECT_SERVICE = "_adb-tls-connect._tcp."
private const val LOCALHOST = "127.0.0.1"

/**
 * Built-in wireless-debugging unlock route.
 *
 * The previous implementation of this class was a simulation: it emitted progress strings
 * separated by delay() calls and then reported success without ever pairing, connecting, or
 * running a command. libadb-android was declared in Gradle but never imported. This version
 * actually performs the pair -> connect -> `pm disable-user` sequence and reports real failures.
 */
class BuiltInAdbRoute(private val context: Context) {

    private val nsdManager by lazy {
        context.getSystemService(Context.NSD_SERVICE) as NsdManager
    }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val pairingNotification by lazy { PairingNotification(context) }

    // replay so progress emitted before Dart subscribes to the EventChannel is not dropped.
    private val _progress = MutableSharedFlow<String>(replay = 32, extraBufferCapacity = 64)
    val progressEvents: SharedFlow<String> = _progress.asSharedFlow()

    /** resolveService is single-flight: a second concurrent resolve throws "listener already in use". */
    private val resolveMutex = Mutex()

    @Volatile private var pairingPort: Int = -1
    @Volatile private var connectPort: Int = -1

    private var pairingListener: NsdManager.DiscoveryListener? = null
    private var connectListener: NsdManager.DiscoveryListener? = null

    fun startDiscovery() {
        emit("Looking for wireless debugging on this device…")
        pairingPort = -1
        connectPort = -1

        pairingListener = discoveryListener(PAIRING_SERVICE) { port ->
            pairingPort = port
            emit("Pairing service found on port $port.")
            // The pairing dialog is open right now; grab the code from the shade before it closes.
            pairingNotification.show { code -> submitPairingCode(code) { _, _ -> } }
        }
        connectListener = discoveryListener(CONNECT_SERVICE) { port ->
            connectPort = port
            emit("Debug port found on port $port.")
            // adbd is the real source of truth for whether we are paired: it stores our public
            // key. If an identity exists but we have no marker (paired by an older build, or
            // the marker was lost), prove it with a silent connect instead of making the user
            // pair again for no reason.
            if (!isPaired()) scope.launch { probeExistingPairing(port) }
        }

        runCatching {
            nsdManager.discoverServices(PAIRING_SERVICE, NsdManager.PROTOCOL_DNS_SD, pairingListener)
        }.onFailure { emit("Could not start pairing discovery: ${it.message}") }
        runCatching {
            nsdManager.discoverServices(CONNECT_SERVICE, NsdManager.PROTOCOL_DNS_SD, connectListener)
        }.onFailure { emit("Could not start connect discovery: ${it.message}") }
    }

    fun stopDiscovery() {
        pairingListener?.let { runCatching { nsdManager.stopServiceDiscovery(it) } }
        connectListener?.let { runCatching { nsdManager.stopServiceDiscovery(it) } }
        pairingListener = null
        connectListener = null
        pairingNotification.dismiss()
    }

    /** True when a debug port has been discovered, so an ADB restore is worth attempting. */
    fun canUseAdb(): Boolean = connectPort != -1

    /**
     * Pairing is one-time. adbd stores our public key, so every later operation needs only
     * connect() — no code, no dialog. This marker records that a pair has succeeded once.
     */
    private val pairedMarker: File
        get() = File(File(context.filesDir, "adb").apply { mkdirs() }, "paired")

    fun isPaired(): Boolean = pairedMarker.exists()

    private fun probeExistingPairing(port: Int) {
        val identity = File(File(context.filesDir, "adb"), "adbkey")
        if (!identity.exists()) return
        val manager = AdbConnectionManager.getInstance(context) ?: return
        val connected = runCatching { manager.connect(LOCALHOST, port) }.getOrDefault(false)
        if (connected) {
            runCatching { pairedMarker.writeText("1") }
            runCatching { manager.close() }
            emit("Already paired with this phone — no code needed.")
        }
    }

    fun forgetPairing() {
        runCatching { pairedMarker.delete() }
    }

    /** Disables the consumers over an existing pairing — no pairing code required. */
    fun disableViaAdb(onResult: (Boolean, String) -> Unit) {
        scope.launch { connectThen(disable = true, onResult = onResult) }
    }

    fun dispose() {
        stopDiscovery()
        scope.cancel()
    }

    /**
     * Pairs with the local adbd, connects, and disables the consumer packages.
     * [onResult] fires exactly once.
     */
    fun submitPairingCode(code: String, onResult: (Boolean, String) -> Unit) {
        val port = pairingPort
        if (port == -1) {
            // Never fall back to connectPort: pairing and connect are different endpoints and
            // pairing on the connect port always fails.
            onResult(false, "Open \"Pair device with pairing code\" in Wireless debugging first.")
            return
        }
        if (code.length != 6 || code.any { !it.isDigit() }) {
            onResult(false, "The pairing code is 6 digits.")
            return
        }

        scope.launch {
            val manager = AdbConnectionManager.getInstance(context)
            if (manager == null) {
                finish(onResult, false, "Could not create the ADB identity for this device.")
                return@launch
            }

            emit("Pairing with $LOCALHOST:$port…")
            val paired = runCatching { manager.pair(LOCALHOST, port, code) }
                .onFailure { Log.w(TAG, "pair failed", it) }
                .getOrDefault(false)
            if (!paired) {
                finish(onResult, false, "Pairing rejected. Check the code and try again.")
                return@launch
            }
            emit("Paired.")
            runCatching { pairedMarker.writeText("1") }   // never ask for a code again
            pairingNotification.dismiss()

            // The connect port is advertised separately and may resolve slightly later.
            val target = withTimeoutOrNull(10_000) {
                while (connectPort == -1) kotlinx.coroutines.delay(200)
                connectPort
            }
            if (target == null) {
                finish(onResult, false, "Paired, but no debug port was advertised. Is wireless debugging still on?")
                return@launch
            }

            emit("Connecting to $LOCALHOST:$target…")
            val connected = runCatching { manager.connect(LOCALHOST, target) }
                .onFailure { Log.w(TAG, "connect failed", it) }
                .getOrDefault(false)
            if (!connected) {
                finish(onResult, false, "Paired, but the connection was refused.")
                return@launch
            }
            emit("Connected.")

            applyToConsumers(manager, disable = true, onResult = onResult)
        }
    }

    /**
     * Re-enables the consumer packages over an already-paired connection.
     * adbd remembers our public key, so this needs connect() only — no second pairing.
     */
    fun restoreViaAdb(onResult: (Boolean, String) -> Unit) {
        scope.launch { connectThen(disable = false, onResult = onResult) }
    }

    /** Shared connect-and-apply used by both directions once a pairing already exists. */
    private fun connectThen(disable: Boolean, onResult: (Boolean, String) -> Unit) {
        val manager = AdbConnectionManager.getInstance(context)
        if (manager == null) {
            finish(onResult, false, "Could not create the ADB identity for this device.")
            return
        }
        val target = connectPort
        if (target == -1) {
            finish(onResult, false, "Turn Wireless debugging on so the debug port is advertised.")
            return
        }
        emit("Connecting to $LOCALHOST:$target…")
        val connected = runCatching { manager.connect(LOCALHOST, target) }
            .onFailure { Log.w(TAG, "connect failed", it) }
            .getOrDefault(false)
        if (!connected) {
            finish(onResult, false, "Not paired with this device yet — pair once first.")
            return
        }
        applyToConsumers(manager, disable = disable, onResult = onResult)
    }

    private fun applyToConsumers(
        manager: AdbConnectionManager,
        disable: Boolean,
        onResult: (Boolean, String) -> Unit
    ) {
        val packages = ConsumerPackages.forUnlock(context)
        if (packages.isEmpty()) {
            finish(onResult, false, "No Essential Space packages are installed on this device.")
            return
        }

        val verb = if (disable) "Disabling" else "Restoring"
        val expected = if (disable) "disabled-user" else "enabled"
        val failures = mutableListOf<String>()

        for (pkg in packages) {
            emit("$verb $pkg…")
            val command =
                if (disable) "pm disable-user --user 0 $pkg" else "pm enable $pkg"
            val output = runShell(manager, command)
            if (output == null || !output.contains(expected, ignoreCase = true)) {
                failures += pkg
                emit("  ! $pkg: ${output?.trim() ?: "no output"}")
            } else {
                emit("  ✓ $pkg")
            }
        }

        runCatching { manager.close() }

        when {
            failures.isNotEmpty() ->
                finish(onResult, false, "Could not update: ${failures.joinToString()}")
            disable -> finish(onResult, true, "Single press is free.")
            else -> finish(onResult, true, "Essential Space restored.")
        }
    }

    private fun runShell(manager: AdbConnectionManager, command: String): String? = try {
        manager.openStream("shell:$command").use { stream ->
            stream.openInputStream().bufferedReader().use(BufferedReader::readText)
        }
    } catch (e: Throwable) {
        Log.w(TAG, "shell failed: $command", e)
        null
    }

    private fun finish(onResult: (Boolean, String) -> Unit, ok: Boolean, message: String) {
        emit(message)
        onResult(ok, message)
    }

    private fun emit(message: String) {
        _progress.tryEmit(message)
    }

    private fun discoveryListener(
        serviceType: String,
        onPort: (Int) -> Unit
    ) = object : NsdManager.DiscoveryListener {
        override fun onDiscoveryStarted(regType: String) {}

        override fun onServiceFound(service: NsdServiceInfo) {
            if (!service.serviceType.contains(serviceType.trim('.'))) return
            scope.launch {
                // Serialised: concurrent resolves throw "listener already in use".
                resolveMutex.withLock {
                    val resolved = withTimeoutOrNull(5_000) { resolve(service) }
                    if (resolved != null && resolved.port > 0) onPort(resolved.port)
                }
            }
        }

        override fun onServiceLost(service: NsdServiceInfo) {
            if (service.serviceType.contains(PAIRING_SERVICE.trim('.'))) pairingPort = -1
        }

        override fun onDiscoveryStopped(serviceType: String) {}
        override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
            emit("Discovery failed ($errorCode). Is Wi-Fi on?")
        }
        override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
    }

    private suspend fun resolve(service: NsdServiceInfo): NsdServiceInfo? =
        suspendCancellableCoroutine { cont ->
            val listener = object : NsdManager.ResolveListener {
                override fun onResolveFailed(serviceInfo: NsdServiceInfo?, errorCode: Int) {
                    if (cont.isActive) cont.resume(null)
                }
                override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                    if (cont.isActive) cont.resume(serviceInfo)
                }
            }
            runCatching { nsdManager.resolveService(service, listener) }
                .onFailure { if (cont.isActive) cont.resume(null) }
        }

    companion object {
        private const val TAG = "BuiltInAdbRoute"
    }
}
