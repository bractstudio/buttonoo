package dev.buttonooo.essential_key.apps

import android.content.Context
import android.content.pm.LauncherApps
import android.os.Process

data class ShortcutItem(
    val id: String,
    val packageName: String,
    val shortLabel: String
)

class Shortcuts(private val context: Context) {
    fun queryShortcuts(packageName: String): List<ShortcutItem> {
        val launcherApps = context.getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps ?: return emptyList()
        return try {
            val query = LauncherApps.ShortcutQuery().apply {
                setPackage(packageName)
                setQueryFlags(
                    LauncherApps.ShortcutQuery.FLAG_MATCH_MANIFEST or
                    LauncherApps.ShortcutQuery.FLAG_MATCH_DYNAMIC or
                    LauncherApps.ShortcutQuery.FLAG_MATCH_PINNED
                )
            }
            val shortcuts = launcherApps.getShortcuts(query, Process.myUserHandle()) ?: emptyList()
            shortcuts.map {
                ShortcutItem(
                    id = it.id,
                    packageName = it.`package`,
                    shortLabel = (it.shortLabel ?: it.id).toString()
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
