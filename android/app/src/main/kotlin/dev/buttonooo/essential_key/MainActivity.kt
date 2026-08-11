package dev.buttonooo.essential_key

import dev.buttonooo.essential_key.bridge.FlowEventStreamHandler
import dev.buttonooo.essential_key.bridge.MethodBridge
import dev.buttonooo.essential_key.service.KeyEventBus
import dev.buttonooo.essential_key.unlock.routes.BuiltInAdbRoute
import dev.buttonooo.essential_key.unlock.routes.ShizukuRoute
import rikka.shizuku.Shizuku
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import org.lsposed.hiddenapibypass.HiddenApiBypass

class MainActivity: FlutterActivity() {

    private val activityScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // The ADB pairing flow posts a notification with an inline reply field — that is the
        // only way to enter the code without backgrounding (and so cancelling) the system
        // pairing dialog. On Android 13+ POST_NOTIFICATIONS is a runtime permission, so
        // without this the notification is silently dropped and pairing cannot complete.
        if (androidx.core.content.ContextCompat.checkSelfPermission(
                this, android.Manifest.permission.POST_NOTIFICATIONS
            ) != android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            androidx.core.app.ActivityCompat.requestPermissions(
                this, arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 4129
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            HiddenApiBypass.addHiddenApiExemptions("")
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Shizuku hands its binder over asynchronously. Without these listeners a cold start
        // races the binder and every availability check answers "not running".
        Shizuku.addBinderReceivedListenerSticky { ShizukuRoute.binderReceived = true }
        Shizuku.addBinderDeadListener { ShizukuRoute.binderReceived = false }
        Shizuku.addRequestPermissionResultListener { _, _ -> /* UI re-reads shizukuState */ }

        val binaryMessenger = flutterEngine.dartExecutor.binaryMessenger
        val adbRoute = BuiltInAdbRoute(context)

        // MethodChannel
        val methodChannel = MethodChannel(binaryMessenger, "dev.buttonooo.essential_key/methods")
        methodChannel.setMethodCallHandler(MethodBridge(context, activityScope, adbRoute))

        // EventChannel: keyEvents
        val keyEventChannel = EventChannel(binaryMessenger, "dev.buttonooo.essential_key/keyEvents")
        keyEventChannel.setStreamHandler(
            FlowEventStreamHandler(activityScope, KeyEventBus.rawEvents) { event ->
                mapOf(
                    "keyCode" to event.keyCode,
                    "scanCode" to event.scanCode,
                    "action" to event.action,
                    "eventTime" to event.eventTime
                )
            }
        )

        // EventChannel: adbProgress
        val adbProgressChannel = EventChannel(binaryMessenger, "dev.buttonooo.essential_key/adbProgress")
        adbProgressChannel.setStreamHandler(
            FlowEventStreamHandler(activityScope, adbRoute.progressEvents) { msg -> msg }
        )
    }
}
