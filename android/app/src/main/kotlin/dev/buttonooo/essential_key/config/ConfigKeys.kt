package dev.buttonooo.essential_key.config

import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey

object ConfigKeys {
    val ENABLED = booleanPreferencesKey("enabled")
    val SCAN_CODE = intPreferencesKey("scan_code")
    val LONG_PRESS_MS = intPreferencesKey("long_press_ms")
    val MULTI_TAP_MS = intPreferencesKey("multi_tap_ms")
    val ACTIONS_JSON = stringPreferencesKey("actions_json")
    val OVERLAY_JSON = stringPreferencesKey("overlay_json")
    val LOCK_POLICY_JSON = stringPreferencesKey("lock_policy_json")
    val HAPTICS_JSON = stringPreferencesKey("haptics_json")
    val DEVICE_ANCHOR_EDGE = stringPreferencesKey("device_anchor_edge")
    val DEVICE_ANCHOR_FRACTION = floatPreferencesKey("device_anchor_fraction")
}
