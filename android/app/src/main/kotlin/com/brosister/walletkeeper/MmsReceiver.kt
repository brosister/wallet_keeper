package com.brosister.walletkeeper

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import java.util.concurrent.atomic.AtomicInteger

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
                    val parsed = WalletKeeperNativeFinancialMessageParser.parse(context, body)
                        ?: return@mapNotNull null
                    item to parsed
                }
                val latest = financialRecent.firstOrNull()
                if (latest == null) {
                    pendingResult.finish()
                    return@postDelayed
                }
                val realtime = financialRecent.filter { (item, _) ->
                    MmsReader.shouldEnqueueRealtimeMms(context, item)
                }
                realtime.forEach { (item, _) ->
                    MmsReader.storePendingMms(context, item)
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
                if (realtime.isEmpty()) {
                    pendingResult.finish()
                    return@postDelayed
                }
                val remaining = AtomicInteger(realtime.size)
                realtime.forEach { (item, parsed) ->
                    WalletKeeperNativeCloudSync.enqueueDraft(
                        context = context,
                        payload = item,
                        parsed = parsed,
                        sourceType = "mms",
                        notificationBody = item["body"] as? String ?: "",
                        onComplete = {
                            if (remaining.decrementAndGet() == 0) {
                                pendingResult.finish()
                            }
                        },
                    )
                }
            } catch (_: Exception) {
                pendingResult.finish()
            }
        }, 1500L)
    }
}
