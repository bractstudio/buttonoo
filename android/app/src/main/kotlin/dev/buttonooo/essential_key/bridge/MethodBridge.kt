package dev.buttonooo.essential_key.bridge

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import dev.buttonooo.essential_key.actions.ActionExecutor
import dev.buttonooo.essential_key.apps.Activities
import dev.buttonooo.essential_key.apps.InstalledApps
import dev.buttonooo.essential_key.apps.Shortcuts
import dev.buttonooo.essential_key.config.ConfigJson
import dev.buttonooo.essential_key.config.ConfigStore
import dev.buttonooo.essential_key.core.KeyGesture
import dev.buttonooo.essential_key.overlay.DeviceAnchors
import dev.buttonooo.essential_key.overlay.OverlayController
import dev.buttonooo.essential_key.service.KeyEventBus
import dev.buttonooo.essential_key.service.KeyRemapService
import dev.buttonooo.essential_key.unlock.ConsumerPackages
import dev.buttonooo.essential_key.unlock.UnlockStateReader
import dev.buttonooo.essential_key.unlock.routes.AppInfoRoute
import dev.buttonooo.essential_key.unlock.routes.BuiltInAdbRoute
import dev.buttonooo.essential_key.unlock.routes.ShizukuRoute
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

class MethodBridge(
    private val context: Context,
    private val scope: CoroutineScope,
    private val builtInAdbRoute: BuiltInAdbRoute = BuiltInAdbRoute(context)
) : MethodChannel.MethodCallHandler {

    private val configStore by lazy { ConfigStore.get(context) }
    private val unlockStateReader by lazy { UnlockStateReader(context) }
    private val appInfoRoute by lazy { AppInfoRoute(context) }
    private val shizukuRoute by lazy { ShizukuRoute(context) }
    private val installedAppsQuery by lazy { InstalledApps.get(context) }
    private val shortcutsQuery by lazy { Shortcuts(context) }
    private val activitiesQuery by lazy { Activities(context) }
    private val previewOverlayController by lazy { OverlayController(context) }
    private val previewExecutor by lazy { ActionExecutor(context) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                handleCall(call, result)
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("NATIVE_ERROR", e.localizedMessage, e.stackTraceToString())
                }
            }
        }
    }

    private suspend fun handleCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> {
                val statusMap = mapOf(
                    "serviceRunning" to KeyRemapService.isRunning,
                    "unlockStatus" to unlockStateReader.overallStatus().name,
                    "overlayPermission" to Settings.canDrawOverlays(context),
                    "writeSettingsPermission" to Settings.System.canWrite(context),
                    "notificationPolicyPermission" to isNotificationPolicyGranted(),
                    "batteryOptimizationIgnored" to isBatteryOptimizationIgnored(),
                    "developerOptionsEnabled" to isDeveloperOptionsEnabled()
                )
                withContext(Dispatchers.Main) { result.success(statusMap) }
            }

            "getConfig" -> {
                val sc = configStore.scanCode.first()
                val actMap = configStore.actions.first()
                val timing = configStore.timing.first()
                val ov = configStore.overlay.first()
                val lock = configStore.lockPolicy.first()
                val hap = configStore.haptics.first()
                val en = configStore.enabled.first()
                val edge = configStore.anchorEdge.first()
                val frac = configStore.anchorFraction.first()

                val json = JSONObject().apply {
                    put("scanCode", sc)
                    put("enabled", en)
                    put("longPressMs", timing.longPressMs)
                    put("multiTapMs", timing.multiTapMs)
                    put("anchorEdge", edge)
                    put("anchorFraction", frac)
                    put("actions", JSONObject().apply {
                        for ((g, a) in actMap) {
                            put(g.key, ConfigJson.encodeActionObject(a))
                        }
                    })
                    put("overlay", JSONObject(ConfigJson.encodeOverlay(ov)))
                    put("lockPolicy", JSONObject(ConfigJson.encodeLockPolicy(lock)))
                    put("haptics", JSONObject(ConfigJson.encodeHaptics(hap)))
                }
                withContext(Dispatchers.Main) { result.success(json.toString()) }
            }

            "setEnabled" -> {
                val v = call.argument<Boolean>("value") ?: true
                configStore.setEnabled(v)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "setAction" -> {
                val gKey = call.argument<String>("gesture") ?: ""
                val aObj = JSONObject(call.argument<String>("actionJson") ?: "{}")
                val gesture = KeyGesture.fromKey(gKey)
                if (gesture != null) {
                    val action = ConfigJson.decodeActionObject(aObj)
                    configStore.setAction(gesture, action)
                }
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "setTiming" -> {
                val lp = call.argument<Number>("longPressMs")?.toLong() ?: 500L
                val mt = call.argument<Number>("multiTapMs")?.toLong() ?: 400L
                configStore.setTiming(lp, mt)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "setOverlay" -> {
                val json = call.argument<String>("overlayJson") ?: "{}"
                val cfg = ConfigJson.decodeOverlay(
                    androidx.datastore.preferences.core.preferencesOf(
                        dev.buttonooo.essential_key.config.ConfigKeys.OVERLAY_JSON to json
                    )
                )
                configStore.setOverlay(cfg)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "setLockPolicy" -> {
                val json = call.argument<String>("lockPolicyJson") ?: "{}"
                val map = ConfigJson.decodeLockPolicy(
                    androidx.datastore.preferences.core.preferencesOf(
                        dev.buttonooo.essential_key.config.ConfigKeys.LOCK_POLICY_JSON to json
                    )
                )
                configStore.setLockPolicy(map)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "setHaptics" -> {
                val json = call.argument<String>("hapticsJson") ?: "{}"
                val cfg = ConfigJson.decodeHaptics(
                    androidx.datastore.preferences.core.preferencesOf(
                        dev.buttonooo.essential_key.config.ConfigKeys.HAPTICS_JSON to json
                    )
                )
                configStore.setHaptics(cfg)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "setLearnMode" -> {
                val v = call.argument<Boolean>("value") ?: false
                KeyEventBus.learnMode = v
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "setSuppressActions" -> {
                val v = call.argument<Boolean>("value") ?: false
                KeyEventBus.suppressActions = v
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "setScanCode" -> {
                val v = call.argument<Int>("scanCode") ?: ConfigStore.DEFAULT_SCAN_CODE
                configStore.setScanCode(v)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "detectDevice" -> {
                val anchor = DeviceAnchors.forCurrentDevice()
                val map = mapOf(
                    "device" to android.os.Build.DEVICE,
                    "model" to android.os.Build.MODEL,
                    "anchorEdge" to anchor.edge.name.lowercase(),
                    "anchorFraction" to anchor.fraction
                )
                withContext(Dispatchers.Main) { result.success(map) }
            }

            "setAnchor" -> {
                val edge = call.argument<String>("edge") ?: "left"
                val frac = call.argument<Number>("fraction")?.toFloat() ?: 0.34f
                configStore.setAnchor(edge, frac)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            // sticky=true holds the real overlay on screen while the settings page is open,
            // so edits are seen on the actual thing rather than an in-page approximation.
            "previewOverlay" -> {
                val aJson = JSONObject(call.argument<String>("actionJson") ?: "{}")
                val sticky = call.argument<Boolean>("sticky") ?: false
                val action = ConfigJson.decodeActionObject(aJson)
                val ovCfg = call.argument<String>("overlayJson")?.let {
                    ConfigJson.decodeOverlay(androidx.datastore.preferences.core.preferencesOf(
                        dev.buttonooo.essential_key.config.ConfigKeys.OVERLAY_JSON to it
                    ))
                } ?: configStore.overlay.first()
                val edge = call.argument<String>("edge") ?: configStore.anchorEdge.first()
                val frac = call.argument<Number>("fraction")?.toFloat() ?: configStore.anchorFraction.first()

                previewOverlayController.updateConfig(ovCfg)
                previewOverlayController.updateAnchor(edge, frac)
                val state = previewExecutor.stateFor(action).let { baseState ->
                    if (sticky) {
                        baseState.copy(
                            torchOn = true,
                            rotationLocked = true,
                            dndOn = true,
                            mediaPlaying = true,
                            label = "Preview Accent"
                        )
                    } else {
                        baseState
                    }
                }
                previewOverlayController.show(action, state, sticky)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "dismissPreview" -> {
                previewOverlayController.dismiss()
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "unlockStates" -> {
                val states = unlockStateReader.allStates().map {
                    mapOf(
                        "packageName" to it.packageName,
                        "installed" to it.installed,
                        "freed" to it.freed
                    )
                }
                withContext(Dispatchers.Main) { result.success(states) }
            }

            "openAppInfo" -> {
                val pkg = call.argument<String>("packageName") ?: ""
                appInfoRoute.openAppInfo(pkg)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "shizukuAvailable" -> {
                withContext(Dispatchers.Main) { result.success(shizukuRoute.isReady()) }
            }

            // NOT_INSTALLED | NOT_RUNNING | NEEDS_PERMISSION | READY — the UI needs to know
            // which precondition failed so it can show the right next step instead of a dead end.
            "shizukuState" -> {
                withContext(Dispatchers.Main) { result.success(shizukuRoute.state().name) }
            }

            "requestShizukuPermission" -> {
                val asked = shizukuRoute.requestPermission()
                withContext(Dispatchers.Main) { result.success(asked) }
            }

            "runShizukuUnlock" -> {
                val ok = shizukuRoute.disableConsumerPackages()
                withContext(Dispatchers.Main) { result.success(ok) }
            }

            // Restore must never depend on Shizuku alone — that made it unreachable whenever
            // Shizuku was unavailable, which is exactly when a user is most likely to want out.
            // Restore tries every route it can, cheapest first, and only falls back to sending
            // the user to App Info when nothing automatic is available.
            "restoreEssentialSpace" -> {
                if (shizukuRoute.isReady() && shizukuRoute.enableConsumerPackages()) {
                    withContext(Dispatchers.Main) { result.success("shizuku") }
                } else if (builtInAdbRoute.canUseAdb()) {
                    val replied = java.util.concurrent.atomic.AtomicBoolean(false)
                    builtInAdbRoute.restoreViaAdb { ok, _ ->
                        if (replied.compareAndSet(false, true)) {
                            scope.launch(Dispatchers.Main) {
                                if (ok) {
                                    result.success("adb")
                                } else {
                                    ConsumerPackages.forUnlock(context).firstOrNull()
                                        ?.let { appInfoRoute.openAppInfo(it) }
                                    result.success("app_info")
                                }
                            }
                        }
                    }
                } else {
                    ConsumerPackages.forUnlock(context).firstOrNull()
                        ?.let { appInfoRoute.openAppInfo(it) }
                    withContext(Dispatchers.Main) { result.success("app_info") }
                }
            }

            "startAdbDiscovery" -> {
                builtInAdbRoute.startDiscovery()
                withContext(Dispatchers.Main) { result.success(null) }
            }

            // Pairing is one-time; these let the UI skip the code entirely afterwards.
            "adbIsPaired" -> {
                withContext(Dispatchers.Main) { result.success(builtInAdbRoute.isPaired()) }
            }

            "adbForgetPairing" -> {
                builtInAdbRoute.forgetPairing()
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "adbDisable" -> {
                val replied = java.util.concurrent.atomic.AtomicBoolean(false)
                builtInAdbRoute.disableViaAdb { ok, msg ->
                    if (replied.compareAndSet(false, true)) {
                        scope.launch(Dispatchers.Main) {
                            result.success(mapOf("ok" to ok, "message" to msg))
                        }
                    }
                }
            }

            "stopAdbDiscovery" -> {
                builtInAdbRoute.stopDiscovery()
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "submitPairingCode" -> {
                val code = call.argument<String>("code") ?: ""
                // The callback must reply exactly once — a second result.success() on the same
                // Result crashes the engine with "Reply already submitted".
                val replied = java.util.concurrent.atomic.AtomicBoolean(false)
                builtInAdbRoute.submitPairingCode(code) { ok, msg ->
                    if (replied.compareAndSet(false, true)) {
                        scope.launch(Dispatchers.Main) {
                            result.success(mapOf("ok" to ok, "message" to msg))
                        }
                    }
                }
            }

            // Labels only. Icons are a separate call so a list of names does not cost a bitmap
            // per installed app — see InstalledApps.
            "installedApps" -> {
                val list = installedAppsQuery.launcherApps().map { app ->
                    mapOf(
                        "packageName" to app.packageName,
                        "label" to app.label
                    )
                }
                withContext(Dispatchers.Main) { result.success(list) }
            }

            "appLabels" -> {
                val packages = call.argument<List<String>>("packageNames") ?: emptyList()
                val labels = installedAppsQuery.labelsFor(packages)
                withContext(Dispatchers.Main) { result.success(labels) }
            }

            "appIcon" -> {
                val pkg = call.argument<String>("packageName") ?: ""
                val size = call.argument<Int>("sizePx") ?: DEFAULT_ICON_PX
                val bytes = installedAppsQuery.iconFor(pkg, size)
                withContext(Dispatchers.Main) { result.success(bytes) }
            }

            "shortcutHostPermission" -> {
                val ok = shortcutsQuery.hasHostPermission()
                withContext(Dispatchers.Main) { result.success(ok) }
            }

            "shortcuts" -> {
                val pkg = call.argument<String>("packageName") ?: ""
                val list = shortcutsQuery.queryShortcuts(pkg).map { sc ->
                    mapOf(
                        "id" to sc.id,
                        "packageName" to sc.packageName,
                        "shortLabel" to sc.shortLabel
                    )
                }
                withContext(Dispatchers.Main) { result.success(list) }
            }

            "activities" -> {
                val pkg = call.argument<String>("packageName") ?: ""
                val list = activitiesQuery.queryActivities(pkg).map { act ->
                    mapOf(
                        "className" to act.className,
                        "packageName" to act.packageName,
                        "name" to act.name
                    )
                }
                withContext(Dispatchers.Main) { result.success(list) }
            }

            "openAccessibilitySettings" -> {
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "openOverlayPermission" -> {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${context.packageName}")
                ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                context.startActivity(intent)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "openWriteSettings" -> {
                val intent = Intent(
                    Settings.ACTION_MANAGE_WRITE_SETTINGS,
                    Uri.parse("package:${context.packageName}")
                ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                context.startActivity(intent)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "openDndAccess" -> {
                val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "openBatteryOptimization" -> {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            "openDeveloperOptions" -> {
                val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            // Deep-links straight to Wireless debugging rather than dumping the user at the top
            // of Developer options, which is what the old duplicate intent did.
            "openWirelessDebugging" -> {
                val direct = Intent("android.settings.ADB_WIRELESS_SETTINGS")
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                val fallback = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                val target =
                    if (direct.resolveActivity(context.packageManager) != null) direct else fallback
                context.startActivity(target)
                withContext(Dispatchers.Main) { result.success(null) }
            }

            else -> withContext(Dispatchers.Main) { result.notImplemented() }
        }
    }

    private companion object {
        /** 48 dp at xxhdpi — the largest a picker row draws an icon. */
        const val DEFAULT_ICON_PX = 144
    }

    private fun isNotificationPolicyGranted(): Boolean {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? android.app.NotificationManager
        return nm?.isNotificationPolicyAccessGranted == true
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return false
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    private fun isDeveloperOptionsEnabled(): Boolean = Settings.Global.getInt(
        context.contentResolver,
        Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
        0
    ) == 1
}
