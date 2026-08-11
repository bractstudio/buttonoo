package dev.buttonooo.essential_key.unlock.routes

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings

class AppInfoRoute(private val context: Context) {
    fun openAppInfo(packageName: String) {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:$packageName")
        ).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }
}
