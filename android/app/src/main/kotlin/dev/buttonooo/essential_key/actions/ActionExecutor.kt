package dev.buttonooo.essential_key.actions

import android.accessibilityservice.AccessibilityService
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.LauncherApps
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.provider.Settings
import android.view.KeyEvent
import android.widget.Toast
import java.util.concurrent.atomic.AtomicBoolean

class ActionExecutor(
    private val context: Context,
    private val service: AccessibilityService? = null
) {
    private var isTorchOn = false
    private val cameraManager by lazy { context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager }

    private val torchCallback = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        object : CameraManager.TorchCallback() {
            override fun onTorchModeChanged(cameraId: String, enabled: Boolean) {
                super.onTorchModeChanged(cameraId, enabled)
                isTorchOn = enabled
            }
        }
    } else null

    init {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && torchCallback != null) {
            try {
                cameraManager?.registerTorchCallback(torchCallback, Handler(Looper.getMainLooper()))
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun execute(action: KeyAction) {
        try {
            when (action) {
                is KeyAction.None -> {}
                is KeyAction.ToggleFlashlight -> toggleFlashlight()
                is KeyAction.ToggleRotationLock -> toggleRotationLock()
                is KeyAction.RingerCycle -> cycleRingerMode()
                is KeyAction.ToggleDnd -> toggleDnd()
                is KeyAction.VoiceAssistant -> launchVoiceAssistant()
                is KeyAction.VolumeUp -> adjustVolume(AudioManager.ADJUST_RAISE)
                is KeyAction.VolumeDown -> adjustVolume(AudioManager.ADJUST_LOWER)
                is KeyAction.VolumeMute -> adjustVolume(AudioManager.ADJUST_TOGGLE_MUTE)
                is KeyAction.VolumeSlider -> adjustVolume(AudioManager.ADJUST_SAME)
                is KeyAction.BrightnessUp -> adjustBrightness(25)
                is KeyAction.BrightnessDown -> adjustBrightness(-25)
                is KeyAction.MediaPlayPause -> dispatchMediaKey(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
                is KeyAction.MediaNext -> dispatchMediaKey(KeyEvent.KEYCODE_MEDIA_NEXT)
                is KeyAction.MediaPrev -> dispatchMediaKey(KeyEvent.KEYCODE_MEDIA_PREVIOUS)
                is KeyAction.TakeScreenshot -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        service?.performGlobalAction(AccessibilityService.GLOBAL_ACTION_TAKE_SCREENSHOT)
                    }
                }
                is KeyAction.LockScreen -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        service?.performGlobalAction(AccessibilityService.GLOBAL_ACTION_LOCK_SCREEN)
                    }
                }
                is KeyAction.LaunchApp -> launchApp(action.packageName)
                is KeyAction.LaunchShortcut -> launchShortcut(action.packageName, action.shortcutId)
                is KeyAction.LaunchActivity -> launchActivity(action.packageName, action.className)
                is KeyAction.AppsColumn -> {} // Handled via touch overlay in NothingGlowView
            }
        } catch (e: Exception) {
            e.printStackTrace()
            showToast("Failed to execute action: ${e.localizedMessage}")
        }
    }

    private fun toggleFlashlight() {
        val cm = cameraManager ?: return
        try {
            val cameraId = cm.cameraIdList.firstOrNull { id ->
                val chars = cm.getCameraCharacteristics(id)
                val facing = chars.get(CameraCharacteristics.LENS_FACING)
                val hasFlash = chars.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) ?: false
                facing == CameraCharacteristics.LENS_FACING_BACK && hasFlash
            }
            if (cameraId != null) {
                val targetMode = !isTorchOn
                cm.setTorchMode(cameraId, targetMode)
                isTorchOn = targetMode
            } else {
                showToast("Flashlight unavailable")
            }
        } catch (e: Exception) {
            showToast("Flashlight error: ${e.localizedMessage}")
        }
    }

    private fun toggleRotationLock() {
        if (!Settings.System.canWrite(context)) {
            showToast("Write Settings permission required for Rotation Lock")
            return
        }
        try {
            val current = Settings.System.getInt(
                context.contentResolver,
                Settings.System.ACCELEROMETER_ROTATION, 0
            )
            val newMode = if (current == 1) 0 else 1
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.ACCELEROMETER_ROTATION, newMode
            )
        } catch (e: Exception) {
            showToast("Rotation lock error: ${e.localizedMessage}")
        }
    }

    private fun cycleRingerMode() {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        val hasDndPolicy = nm?.isNotificationPolicyAccessGranted == true

        val current = audioManager.ringerMode
        val next = if (hasDndPolicy) {
            when (current) {
                AudioManager.RINGER_MODE_NORMAL -> AudioManager.RINGER_MODE_VIBRATE
                AudioManager.RINGER_MODE_VIBRATE -> AudioManager.RINGER_MODE_SILENT
                else -> AudioManager.RINGER_MODE_NORMAL
            }
        } else {
            if (current == AudioManager.RINGER_MODE_SILENT) {
                showToast("Notification Policy permission needed for Silent mode")
            }
            if (current == AudioManager.RINGER_MODE_NORMAL) AudioManager.RINGER_MODE_VIBRATE
            else AudioManager.RINGER_MODE_NORMAL
        }
        audioManager.ringerMode = next
    }

    private fun toggleDnd() {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        if (!nm.isNotificationPolicyAccessGranted) {
            showToast("Notification Policy permission required for DND")
            return
        }
        val currentFilter = nm.currentInterruptionFilter
        val newFilter = if (currentFilter == NotificationManager.INTERRUPTION_FILTER_ALL) {
            NotificationManager.INTERRUPTION_FILTER_PRIORITY
        } else {
            NotificationManager.INTERRUPTION_FILTER_ALL
        }
        nm.setInterruptionFilter(newFilter)
    }

    private fun launchVoiceAssistant() {
        val intent = Intent(Intent.ACTION_VOICE_COMMAND).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            val fallback = Intent(Intent.ACTION_ASSIST).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                context.startActivity(fallback)
            } catch (ex: Exception) {
                showToast("No voice assistant available")
            }
        }
    }

    private fun dispatchMediaKey(keyCode: Int) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        val down = KeyEvent(SystemClock.uptimeMillis(), SystemClock.uptimeMillis(), KeyEvent.ACTION_DOWN, keyCode, 0)
        val up = KeyEvent(SystemClock.uptimeMillis(), SystemClock.uptimeMillis(), KeyEvent.ACTION_UP, keyCode, 0)
        audioManager.dispatchMediaKeyEvent(down)
        audioManager.dispatchMediaKeyEvent(up)
    }

    private fun launchApp(packageName: String) {
        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } else {
            showToast("App not found: $packageName")
        }
    }

    private fun launchShortcut(packageName: String, shortcutId: String) {
        val launcher = context.getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps
        if (launcher != null) {
            try {
                launcher.startShortcut(packageName, shortcutId, null, null, Process.myUserHandle())
            } catch (e: Exception) {
                showToast("Failed to launch shortcut: ${e.localizedMessage}")
            }
        }
    }

    private fun launchActivity(packageName: String, className: String) {
        val intent = Intent().apply {
            component = ComponentName(packageName, className)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            showToast("Failed to launch activity: ${e.localizedMessage}")
        }
    }

    fun stateFor(action: KeyAction): ActionState {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        val rot = Settings.System.getInt(
            context.contentResolver,
            Settings.System.ACCELEROMETER_ROTATION, 0
        )
        val dnd = nm?.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL
        val musicActive = audioManager?.isMusicActive ?: false

        return ActionState(
            torchOn = isTorchOn,
            rotationLocked = (rot == 0),
            ringerMode = audioManager?.ringerMode ?: AudioManager.RINGER_MODE_NORMAL,
            dndOn = dnd,
            mediaPlaying = musicActive,
            label = when (action) {
                is KeyAction.ToggleFlashlight -> if (isTorchOn) "Flashlight On" else "Flashlight Off"
                is KeyAction.ToggleRotationLock -> if (rot == 0) "Rotation Locked" else "Auto Rotate"
                is KeyAction.RingerCycle -> when (audioManager?.ringerMode) {
                    AudioManager.RINGER_MODE_SILENT -> "Silent"
                    AudioManager.RINGER_MODE_VIBRATE -> "Vibrate"
                    else -> "Ring"
                }
                is KeyAction.ToggleDnd -> if (dnd) "DND On" else "DND Off"
                is KeyAction.VoiceAssistant -> "Assistant"
                is KeyAction.MediaPlayPause -> "Play/Pause"
                is KeyAction.MediaNext -> "Next Track"
                is KeyAction.MediaPrev -> "Previous Track"
                is KeyAction.TakeScreenshot -> "Screenshot"
                is KeyAction.LockScreen -> "Screen Locked"
                is KeyAction.LaunchApp -> "Launch App"
                is KeyAction.LaunchShortcut -> "Shortcut"
                is KeyAction.LaunchActivity -> "Activity"
                is KeyAction.AppsColumn -> "Apps Column"
                else -> ""
            }
        )
    }

    private fun adjustVolume(direction: Int) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        audioManager.adjustVolume(direction, AudioManager.FLAG_SHOW_UI)
    }

    private fun adjustBrightness(delta: Int) {
        if (!Settings.System.canWrite(context)) {
            showToast("Write Settings permission required for Brightness control")
            return
        }
        try {
            val current = Settings.System.getInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS, 128
            )
            val newBrightness = (current + delta).coerceIn(0, 255)
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS, newBrightness
            )
        } catch (e: Exception) {
            showToast("Brightness error: ${e.localizedMessage}")
        }
    }

    private fun showToast(msg: String) {
        Toast.makeText(context.applicationContext, msg, Toast.LENGTH_SHORT).show()
    }
}
