package dev.buttonooo.essential_key.config

import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.MutablePreferences
import dev.buttonooo.essential_key.actions.KeyAction
import dev.buttonooo.essential_key.core.KeyGesture
import org.json.JSONObject

data class OverlayConfig(
    val enabled: Boolean = true,
    val style: String = "nothing", // "nothing" or "stock"
    val accentHex: String = "#FFD300",
    val glow: Boolean = true,
    val holdMs: Long = 700L,
    val panelSize: String = "Regular", // "Small", "Regular", "Large" — seeds the dp values below
    // Explicit dp geometry so the settings page can actually change the shape.
    // The small card is what most actions show; only volume, brightness and the
    // shortcut column extend into the tall panel.
    val cardWidthDp: Int = 46,
    val cardHeightDp: Int = 80,
    val panelWidthDp: Int = 56,
    val panelHeightDp: Int = 148,
    val edgeMarginDp: Int = 9,
    val cardStyle: String = "filled", // "filled", "stroke", "transparent"
    val cornerRadiusDp: Int = 18
)

data class HapticConfig(
    val enabled: Boolean = true,
    val intensity: String = "medium" // "light", "medium", "heavy"
)

object ConfigJson {

    fun decodeActions(prefs: Preferences): Map<KeyGesture, KeyAction> {
        val raw = prefs[ConfigKeys.ACTIONS_JSON] ?: return emptyMap()
        val result = mutableMapOf<KeyGesture, KeyAction>()
        try {
            val json = JSONObject(raw)
            for (gesture in KeyGesture.values()) {
                if (json.has(gesture.key)) {
                    val obj = json.getJSONObject(gesture.key)
                    result[gesture] = decodeActionObject(obj)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return result
    }

    fun encodeActions(map: Map<KeyGesture, KeyAction>): String {
        val json = JSONObject()
        for ((g, a) in map) {
            json.put(g.key, encodeActionObject(a))
        }
        return json.toString()
    }

    fun decodeActionObject(obj: JSONObject): KeyAction {
        return when (obj.optString("type")) {
            "quick" -> when (obj.optString("id")) {
                "flashlight" -> KeyAction.ToggleFlashlight
                "rotation_lock" -> KeyAction.ToggleRotationLock
                "ring_vibrate" -> KeyAction.RingerCycle
                "dnd" -> KeyAction.ToggleDnd
                "assistant" -> KeyAction.VoiceAssistant
                "volume_up" -> KeyAction.VolumeUp
                "volume_down" -> KeyAction.VolumeDown
                "volume_mute" -> KeyAction.VolumeMute
                "volume_slider" -> KeyAction.VolumeSlider
                "brightness_up" -> KeyAction.BrightnessUp
                "brightness_down" -> KeyAction.BrightnessDown
                "media_play_pause" -> KeyAction.MediaPlayPause
                "media_next" -> KeyAction.MediaNext
                "media_prev" -> KeyAction.MediaPrev
                "screenshot" -> KeyAction.TakeScreenshot
                "lock_screen" -> KeyAction.LockScreen
                else -> KeyAction.None
            }
            "app" -> KeyAction.LaunchApp(obj.optString("package"))
            "shortcut" -> KeyAction.LaunchShortcut(obj.optString("package"), obj.optString("shortcutId"))
            "activity" -> KeyAction.LaunchActivity(obj.optString("package"), obj.optString("className"))
            "apps_column" -> {
                val arr = obj.optJSONArray("packageNames")
                val list = mutableListOf<String>()
                if (arr != null) {
                    for (i in 0 until arr.length()) {
                        list.add(arr.getString(i))
                    }
                }
                KeyAction.AppsColumn(list)
            }
            else -> KeyAction.None
        }
    }

    fun encodeActionObject(action: KeyAction): JSONObject {
        val obj = JSONObject()
        when (action) {
            is KeyAction.None -> obj.put("type", "none")
            is KeyAction.ToggleFlashlight -> { obj.put("type", "quick"); obj.put("id", "flashlight") }
            is KeyAction.ToggleRotationLock -> { obj.put("type", "quick"); obj.put("id", "rotation_lock") }
            is KeyAction.RingerCycle -> { obj.put("type", "quick"); obj.put("id", "ring_vibrate") }
            is KeyAction.ToggleDnd -> { obj.put("type", "quick"); obj.put("id", "dnd") }
            is KeyAction.VoiceAssistant -> { obj.put("type", "quick"); obj.put("id", "assistant") }
            is KeyAction.VolumeUp -> { obj.put("type", "quick"); obj.put("id", "volume_up") }
            is KeyAction.VolumeDown -> { obj.put("type", "quick"); obj.put("id", "volume_down") }
            is KeyAction.VolumeMute -> { obj.put("type", "quick"); obj.put("id", "volume_mute") }
            is KeyAction.VolumeSlider -> { obj.put("type", "quick"); obj.put("id", "volume_slider") }
            is KeyAction.BrightnessUp -> { obj.put("type", "quick"); obj.put("id", "brightness_up") }
            is KeyAction.BrightnessDown -> { obj.put("type", "quick"); obj.put("id", "brightness_down") }
            is KeyAction.MediaPlayPause -> { obj.put("type", "quick"); obj.put("id", "media_play_pause") }
            is KeyAction.MediaNext -> { obj.put("type", "quick"); obj.put("id", "media_next") }
            is KeyAction.MediaPrev -> { obj.put("type", "quick"); obj.put("id", "media_prev") }
            is KeyAction.TakeScreenshot -> { obj.put("type", "quick"); obj.put("id", "screenshot") }
            is KeyAction.LockScreen -> { obj.put("type", "quick"); obj.put("id", "lock_screen") }
            is KeyAction.LaunchApp -> { obj.put("type", "app"); obj.put("package", action.packageName) }
            is KeyAction.LaunchShortcut -> {
                obj.put("type", "shortcut")
                obj.put("package", action.packageName)
                obj.put("shortcutId", action.shortcutId)
            }
            is KeyAction.LaunchActivity -> {
                obj.put("type", "activity")
                obj.put("package", action.packageName)
                obj.put("className", action.className)
            }
            is KeyAction.AppsColumn -> {
                obj.put("type", "apps_column")
                val arr = org.json.JSONArray(action.packageNames)
                obj.put("packageNames", arr)
            }
        }
        return obj
    }

    fun decodeOverlay(prefs: Preferences): OverlayConfig {
        val raw = prefs[ConfigKeys.OVERLAY_JSON] ?: return OverlayConfig()
        return try {
            val obj = JSONObject(raw)
            OverlayConfig(
                enabled = obj.optBoolean("enabled", true),
                style = obj.optString("style", "nothing"),
                accentHex = obj.optString("accent", "#FFD300"),
                glow = obj.optBoolean("glow", true),
                holdMs = obj.optLong("holdMs", 700L),
                panelSize = obj.optString("panelSize", "Regular"),
                cardWidthDp = obj.optInt("cardW", 46),
                cardHeightDp = obj.optInt("cardH", 80),
                panelWidthDp = obj.optInt("panelW", 56),
                panelHeightDp = obj.optInt("panelH", 148),
                edgeMarginDp = obj.optInt("edgeMargin", 9),
                cardStyle = obj.optString("cardStyle", "filled"),
                cornerRadiusDp = obj.optInt("cornerRadius", 18)
            )
        } catch (e: Exception) {
            OverlayConfig()
        }
    }

    fun encodeOverlay(cfg: OverlayConfig): String {
        return JSONObject().apply {
            put("enabled", cfg.enabled)
            put("style", cfg.style)
            put("accent", cfg.accentHex)
            put("glow", cfg.glow)
            put("holdMs", cfg.holdMs)
            put("panelSize", cfg.panelSize)
            put("cardW", cfg.cardWidthDp)
            put("cardH", cfg.cardHeightDp)
            put("panelW", cfg.panelWidthDp)
            put("panelH", cfg.panelHeightDp)
            put("edgeMargin", cfg.edgeMarginDp)
            put("cardStyle", cfg.cardStyle)
            put("cornerRadius", cfg.cornerRadiusDp)
        }.toString()
    }


    fun decodeLockPolicy(prefs: Preferences): Map<KeyGesture, Boolean> {
        val raw = prefs[ConfigKeys.LOCK_POLICY_JSON] ?: return emptyMap()
        val result = mutableMapOf<KeyGesture, Boolean>()
        try {
            val json = JSONObject(raw)
            for (gesture in KeyGesture.values()) {
                if (json.has(gesture.key)) {
                    result[gesture] = json.getBoolean(gesture.key)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return result
    }

    fun encodeLockPolicy(map: Map<KeyGesture, Boolean>): String {
        val json = JSONObject()
        for ((g, v) in map) {
            json.put(g.key, v)
        }
        return json.toString()
    }

    fun decodeHaptics(prefs: Preferences): HapticConfig {
        val raw = prefs[ConfigKeys.HAPTICS_JSON] ?: return HapticConfig()
        return try {
            val obj = JSONObject(raw)
            HapticConfig(
                enabled = obj.optBoolean("enabled", true),
                intensity = obj.optString("intensity", "medium")
            )
        } catch (e: Exception) {
            HapticConfig()
        }
    }

    fun encodeHaptics(cfg: HapticConfig): String {
        return JSONObject().apply {
            put("enabled", cfg.enabled)
            put("intensity", cfg.intensity)
        }.toString()
    }
}
