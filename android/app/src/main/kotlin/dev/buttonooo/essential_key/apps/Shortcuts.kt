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
    /// Both LauncherApps.getShortcuts and startShortcut are gated on the caller
    /// holding shortcut host permission, which the platform grants only to the
    /// current default launcher. Without it getShortcuts throws SecurityException
    /// and every app looks like it publishes nothing, so ask first and let the UI
    /// say what is actually wrong.
    fun hasHostPermission(): Boolean {
        val launcherApps = context.getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps
            ?: return false
        return try {
            launcherApps.hasShortcutHostPermission()
        } catch (e: Exception) {
            false
        }
    }

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
