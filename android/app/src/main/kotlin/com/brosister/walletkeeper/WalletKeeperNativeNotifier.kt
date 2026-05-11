package com.brosister.walletkeeper

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object WalletKeeperNativeNotifier {
    private const val CHANNEL_ID = "wallet_keeper_sms_channel"
    private const val CHANNEL_NAME = "지갑지켜 문자 알림"
    private const val OPEN_SMS_INBOX_ACTION = "com.brosister.walletkeeper.OPEN_SMS_INBOX"
    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
    private const val SHOW_NOTIFICATION_PREF_KEY =
        "flutter.wallet_keeper_sms_show_notification_v1"

    fun shouldShowFinancialNotification(context: Context): Boolean {
        return context
            .getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(SHOW_NOTIFICATION_PREF_KEY, true)
    }

    fun showFinancialNotification(
        context: Context,
        notificationId: Int,
        title: String,
        amountText: String,
        timestampMillis: Long,
    ) {
        ensureChannel(context)
        val contentIntent = PendingIntent.getActivity(
            context,
            notificationId,
            Intent(context, MainActivity::class.java).apply {
                action = OPEN_SMS_INBOX_ACTION
                flags =
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_wallet_keeper_white)
            .setContentTitle(title)
            .setContentText(amountText)
            .setColor(0xFFE76158.toInt())
            .setColorized(true)
            .setWhen(timestampMillis)
            .setShowWhen(true)
            .setStyle(NotificationCompat.BigTextStyle().bigText(amountText))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .setOnlyAlertOnce(true)
            .build()

        NotificationManagerCompat.from(context).notify(notificationId, notification)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            )
        )
    }
}
