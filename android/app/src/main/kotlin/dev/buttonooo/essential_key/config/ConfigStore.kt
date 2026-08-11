package dev.buttonooo.essential_key.config

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import dev.buttonooo.essential_key.actions.KeyAction
import dev.buttonooo.essential_key.core.GestureTiming
import dev.buttonooo.essential_key.core.KeyGesture
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "essential_key_config")

class ConfigStore private constructor(private val ds: DataStore<Preferences>) {

    val scanCode: Flow<Int> = ds.data.map { it[ConfigKeys.SCAN_CODE] ?: DEFAULT_SCAN_CODE }

    val actions: Flow<Map<KeyGesture, KeyAction>> = ds.data.map { ConfigJson.decodeActions(it) }

    val timing: Flow<GestureTiming> = ds.data.map {
        GestureTiming(
            longPressMs = (it[ConfigKeys.LONG_PRESS_MS] ?: 500).toLong(),
            multiTapMs = (it[ConfigKeys.MULTI_TAP_MS] ?: 400).toLong()
        )
    }

    val overlay: Flow<OverlayConfig> = ds.data.map { ConfigJson.decodeOverlay(it) }

    val lockPolicy: Flow<Map<KeyGesture, Boolean>> = ds.data.map { ConfigJson.decodeLockPolicy(it) }

    val haptics: Flow<HapticConfig> = ds.data.map { ConfigJson.decodeHaptics(it) }

    val enabled: Flow<Boolean> = ds.data.map { it[ConfigKeys.ENABLED] ?: true }

    // Unset falls back to the per-device seed rather than a hardcoded "left", which is what
    // pinned the overlay to the left edge on every device.
    val anchorEdge: Flow<String> = ds.data.map {
        it[ConfigKeys.DEVICE_ANCHOR_EDGE]
            ?: dev.buttonooo.essential_key.overlay.DeviceAnchors.forCurrentDevice().edge.name.lowercase()
    }

    val anchorFraction: Flow<Float> = ds.data.map {
        it[ConfigKeys.DEVICE_ANCHOR_FRACTION]
            ?: dev.buttonooo.essential_key.overlay.DeviceAnchors.forCurrentDevice().fraction
    }

    suspend fun setScanCode(v: Int) = ds.edit { it[ConfigKeys.SCAN_CODE] = v }

    suspend fun setEnabled(v: Boolean) = ds.edit { it[ConfigKeys.ENABLED] = v }

    suspend fun setAction(g: KeyGesture, a: KeyAction) = ds.edit { prefs ->
        val current = ConfigJson.decodeActions(prefs).toMutableMap()
        current[g] = a
        prefs[ConfigKeys.ACTIONS_JSON] = ConfigJson.encodeActions(current)
    }

    suspend fun setTiming(longPressMs: Long, multiTapMs: Long) = ds.edit {
        it[ConfigKeys.LONG_PRESS_MS] = longPressMs.toInt()
        it[ConfigKeys.MULTI_TAP_MS] = multiTapMs.toInt()
    }

    suspend fun setOverlay(cfg: OverlayConfig) = ds.edit {
        it[ConfigKeys.OVERLAY_JSON] = ConfigJson.encodeOverlay(cfg)
    }

    suspend fun setLockPolicy(policy: Map<KeyGesture, Boolean>) = ds.edit {
        it[ConfigKeys.LOCK_POLICY_JSON] = ConfigJson.encodeLockPolicy(policy)
    }

    suspend fun setHaptics(cfg: HapticConfig) = ds.edit {
        it[ConfigKeys.HAPTICS_JSON] = ConfigJson.encodeHaptics(cfg)
    }

    suspend fun setAnchor(edge: String, fraction: Float) = ds.edit {
        it[ConfigKeys.DEVICE_ANCHOR_EDGE] = edge
        it[ConfigKeys.DEVICE_ANCHOR_FRACTION] = fraction
    }

    companion object {
        const val DEFAULT_SCAN_CODE = 250

        @Volatile
        private var instance: ConfigStore? = null

        fun get(context: Context): ConfigStore = instance ?: synchronized(this) {
            instance ?: ConfigStore(context.applicationContext.dataStore).also { instance = it }
        }
    }
}
