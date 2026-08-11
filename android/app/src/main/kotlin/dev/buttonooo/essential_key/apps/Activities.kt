package dev.buttonooo.essential_key.apps

import android.content.Context
import android.content.pm.PackageManager

data class ActivityItem(
    val className: String,
    val packageName: String,
    val name: String
)

class Activities(private val context: Context) {
    fun queryActivities(packageName: String): List<ActivityItem> {
        val pm = context.packageManager
        return try {
            val pkgInfo = pm.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            val activities = pkgInfo.activities ?: return emptyList()
            activities.filter { it.exported }.map {
                ActivityItem(
                    className = it.name,
                    packageName = packageName,
                    name = it.name.substringAfterLast('.')
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
