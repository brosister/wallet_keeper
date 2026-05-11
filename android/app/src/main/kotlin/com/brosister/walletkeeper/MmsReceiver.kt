package com.brosister.walletkeeper

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper

class MmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                val now = System.currentTimeMillis()
                val recent = MmsReader.queryRecentMms(context, recentDays = 1, limit = 8)
                    .filter {
                        val dateMillis = it["dateMillis"] as? Long ?: 0L
                        now - dateMillis <= 3 * 60 * 1000L
                    }
                val financialRecent = recent.mapNotNull { item ->
                    val body = item["body"] as? String ?: return@mapNotNull null
                    val parsed = WalletKeeperNativeFinancialMessageParser.parse(body) ?: return@mapNotNull null
                    item to parsed
                }
                val latest = financialRecent.firstOrNull() ?: return@postDelayed
                recent.forEach {
                    val body = it["body"] as? String ?: return@forEach
                    if (
                        WalletKeeperNativeFinancialMessageParser.parse(body) != null &&
                        MmsReader.shouldEnqueueRealtimeMms(context, it)
                    ) {
                        MmsReader.storePendingMms(context, it)
                    }
                }
                val timestampMillis = (latest.first["dateMillis"] as? Long) ?: now
                if (WalletKeeperNativeNotifier.shouldShowFinancialNotification(context)) {
                    WalletKeeperNativeNotifier.showFinancialNotification(
                        context = context,
                        notificationId = (latest.first["id"] as? String)?.hashCode()
                            ?: ((latest.first["body"] as? String)?.hashCode() ?: now.toInt()),
                        title = latest.second.title,
                        amountText = latest.second.amountText,
                        timestampMillis = timestampMillis,
                    )
                }
            } finally {
                pendingResult.finish()
            }
        }, 1500L)
    }
}
