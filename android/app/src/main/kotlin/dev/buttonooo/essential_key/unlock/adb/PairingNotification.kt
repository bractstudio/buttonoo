package dev.buttonooo.essential_key.unlock.adb

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.app.RemoteInput
import androidx.core.content.ContextCompat

/**
 * Collects the wireless-debugging pairing code without the user leaving the pairing dialog.
 *
 * Android's "Pair device with pairing code" dialog cancels the pairing session the moment it
 * loses foreground, and the _adb-tls-pairing._tcp service is only advertised while it is open.
 * So the user cannot read the code, switch to this app, and type it in — by the time they get
 * here the session is gone. Posting a notification with an inline reply field lets them enter
 * the code from the shade while the dialog stays up. This is the approach Shizuku uses.
 *
 * Needs POST_NOTIFICATIONS only — not notification-listener access.
 */
class PairingNotification(private val context: Context) {

    private var receiver: BroadcastReceiver? = null

    fun show(onCode: (String) -> Unit) {
        ensureChannel()
        registerReceiver(onCode)

        val remoteInput = RemoteInput.Builder(KEY_CODE)
            .setLabel("Pairing code")
            .build()

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            Intent(ACTION_SUBMIT).setPackage(context.packageName),
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val action = Notification.Action.Builder(
            null,
            "Enter pairing code",
            pendingIntent
        ).addRemoteInput(
            android.app.RemoteInput.Builder(KEY_CODE).setLabel("Pairing code").build()
        ).build()

        val notification = Notification.Builder(context, CHANNEL_ID)
            .setContentTitle("Pair this device")
            .setContentText("Type the 6-digit code shown in the Wireless debugging dialog")
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setOngoing(true)
            .addAction(action)
            .build()

        notificationManager().notify(NOTIFICATION_ID, notification)
    }

    fun dismiss() {
        notificationManager().cancel(NOTIFICATION_ID)
        receiver?.let {
            runCatching { context.unregisterReceiver(it) }
            receiver = null
        }
    }

    private fun registerReceiver(onCode: (String) -> Unit) {
        receiver?.let { runCatching { context.unregisterReceiver(it) } }
        val r = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                val received = intent ?: return
                val code = RemoteInput.getResultsFromIntent(received)
                    ?.getCharSequence(KEY_CODE)?.toString()?.trim()
                if (!code.isNullOrEmpty()) onCode(code)
            }
        }
        receiver = r
        ContextCompat.registerReceiver(
            context,
            r,
            IntentFilter(ACTION_SUBMIT),
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    private fun ensureChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Wireless debugging pairing",
            NotificationManager.IMPORTANCE_HIGH
        ).apply { description = "Used only during one-time setup" }
        notificationManager().createNotificationChannel(channel)
    }

    private fun notificationManager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    companion object {
        private const val CHANNEL_ID = "adb_pairing"
        private const val NOTIFICATION_ID = 4128
        private const val KEY_CODE = "pairing_code"
        private const val ACTION_SUBMIT = "dev.buttonooo.essential_key.SUBMIT_PAIRING_CODE"
    }
}
