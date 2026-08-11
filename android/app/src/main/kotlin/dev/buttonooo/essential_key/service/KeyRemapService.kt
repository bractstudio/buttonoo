package dev.buttonooo.essential_key.service

import android.accessibilityservice.AccessibilityService
import android.app.KeyguardManager
import android.content.res.Configuration
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import dev.buttonooo.essential_key.BuildConfig
import dev.buttonooo.essential_key.actions.ActionExecutor
import dev.buttonooo.essential_key.actions.KeyAction
import dev.buttonooo.essential_key.config.ConfigStore
import dev.buttonooo.essential_key.config.HapticConfig
import dev.buttonooo.essential_key.core.HandlerGestureScheduler
import dev.buttonooo.essential_key.core.KeyGesture
import dev.buttonooo.essential_key.core.KeyGestureClassifier
import dev.buttonooo.essential_key.overlay.OverlayController
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

class KeyRemapService : AccessibilityService() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private lateinit var executor: ActionExecutor
    private lateinit var overlay: OverlayController

    private var classifier: KeyGestureClassifier? = null
    private var scanCode = ConfigStore.DEFAULT_SCAN_CODE
    private var actions = emptyMap<KeyGesture, KeyAction>()
    private var lockPolicy = emptyMap<KeyGesture, Boolean>()
    private var hapticConfig = HapticConfig()
    private var enabled = true

    override fun onServiceConnected() {
        super.onServiceConnected()
        isRunning = true

        executor = ActionExecutor(this, this)
        overlay = OverlayController(this)

        val cfg = ConfigStore.get(this)

        scope.launch {
            combine(
                cfg.scanCode,
                cfg.actions,
                cfg.timing,
                cfg.lockPolicy,
                cfg.enabled
            ) { sc, act, timing, lock, on ->
                Quint(sc, act, timing, lock, on)
            }.collect { (sc, act, timing, lock, on) ->
                scanCode = sc
                actions = act
                lockPolicy = lock
                enabled = on

                classifier?.reset()
                classifier = KeyGestureClassifier(
                    enabledGestures = act.filterValues { it !is KeyAction.None }.keys,
                    timing = timing,
                    scheduler = HandlerGestureScheduler(Handler(Looper.getMainLooper())),
                    onGesture = ::onGesture
                )
            }
        }

        scope.launch {
            cfg.overlay.collect { overlay.updateConfig(it) }
        }

        scope.launch {
            combine(cfg.anchorEdge, cfg.anchorFraction) { edge, frac -> Pair(edge, frac) }
                .collect { (edge, frac) -> overlay.updateAnchor(edge, frac) }
        }

        scope.launch {
            cfg.haptics.collect { hapticConfig = it }
        }
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        // Never log key events in a release build. The app's whole claim is that it
        // observes one key and records nothing; an unconditional logcat line would
        // make that untrue for every key on the device.
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "keyCode=${event.keyCode} scanCode=${event.scanCode} action=${event.action}")
        }

        KeyEventBus.publishRaw(event)

        if (KeyEventBus.learnMode) {
            return false
        }

        if (!enabled) return false

        val isScanMatch = (event.scanCode == scanCode) ||
                (event.scanCode == 250 || event.scanCode == 296) ||
                (event.keyCode == KeyEvent.KEYCODE_UNKNOWN && event.scanCode > 0)

        if (!isScanMatch) return false

        when (event.action) {
            KeyEvent.ACTION_DOWN -> classifier?.onKeyDown()
            KeyEvent.ACTION_UP -> classifier?.onKeyUp()
        }

        return true
    }

    private fun onGesture(g: KeyGesture) {
        KeyEventBus.publishGesture(g)
        if (KeyEventBus.suppressActions) return

        val km = getSystemService(KeyguardManager::class.java)
        if (km.isKeyguardLocked && lockPolicy[g] != true) return

        val action = actions[g] ?: KeyAction.None
        if (action is KeyAction.None) return

        executor.execute(action)
        overlay.show(action, executor.stateFor(action))
        triggerHaptics()
    }

    private fun triggerHaptics() {
        if (!hapticConfig.enabled) return
        val vibrator = getSystemService(Context_VIBRATOR_SERVICE) as? Vibrator ?: return
        if (!vibrator.hasVibrator()) return

        val duration = when (hapticConfig.intensity.lowercase()) {
            "light" -> 15L
            "heavy" -> 60L
            else -> 30L // medium
        }

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(duration)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        overlay.onRotationChanged()
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
    }

    companion object {
        private const val TAG = "KeyRemapService"
        const val Context_VIBRATOR_SERVICE = VIBRATOR_SERVICE
        @Volatile var isRunning = false
            private set
    }
}

private data class Quint<A, B, C, D, E>(
    val first: A,
    val second: B,
    val third: C,
    val fourth: D,
    val fifth: E
)
