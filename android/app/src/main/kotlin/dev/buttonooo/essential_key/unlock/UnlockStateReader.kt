package dev.buttonooo.essential_key.unlock

import android.content.Context
import android.content.pm.PackageManager

class UnlockStateReader(private val context: Context) {

    fun stateOf(pkg: String): PackageState {
        val pm = context.packageManager
        val appInfo = try {
            pm.getApplicationInfo(pkg, 0)
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }

        if (appInfo == null) {
            return PackageState(packageName = pkg, installed = false, freed = true)
        }

        val setting = try {
            pm.getApplicationEnabledSetting(pkg)
        } catch (e: Exception) {
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT
        }

        val isDisabledSetting = setting == PackageManager.COMPONENT_ENABLED_STATE_DISABLED ||
                setting == PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER ||
                setting == PackageManager.COMPONENT_ENABLED_STATE_DISABLED_UNTIL_USED

        val freed = !appInfo.enabled || isDisabledSetting

        return PackageState(packageName = pkg, installed = true, freed = freed)
    }

    fun allStates(): List<PackageState> {
        // Report every candidate, including uninstalled ones, so the UI can distinguish
        // "not present on this model" from "present and still active".
        return ConsumerPackages.CANDIDATES.map { stateOf(it) }
    }

    fun overallStatus(): UnlockStatus {
        val states = allStates().filter { it.installed }
        if (states.isEmpty()) return UnlockStatus.NO_CONSUMERS

        val freedCount = states.count { it.freed }
        return when {
            freedCount == states.size -> UnlockStatus.FREED
            freedCount > 0 -> UnlockStatus.PARTIALLY_FREED
            else -> UnlockStatus.LOCKED
        }
    }
}
