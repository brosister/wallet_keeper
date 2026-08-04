package com.brosister.walletkeeper

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class WalletKeeperNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        val notification = sbn ?: return
        val payload =
            WalletKeeperNotificationReader.extractFinancialNotification(this, notification) ?: return
        val notificationId = payload["id"] as? String ?: return
        if (!WalletKeeperNotificationReader.shouldEnqueueRealtimeNotification(this, notificationId)) {
            return
        }
        WalletKeeperNotificationReader.storePendingNotification(this, payload)
        WalletKeeperNativeCloudSync.enqueueDraft(
            context = this,
            payload = payload,
            parsed = NativeFinancialMessage(
                title = payload["title"] as? String ?: "금융 알림",
                amountText = payload["amountText"] as? String ?: "",
            ),
            sourceType = "app_notification",
            sourceAppName = payload["appName"] as? String ?: "",
            notificationTitle = payload["titleHint"] as? String ?: "",
            notificationBody = payload["textBody"] as? String ?: "",
        )
        if (WalletKeeperNativeNotifier.shouldShowFinancialNotification(this)) {
            WalletKeeperNativeNotifier.showFinancialNotification(
                context = this,
                notificationId = notificationId.hashCode(),
                title = payload["title"] as? String ?: "지갑지켜",
                amountText = payload["amountText"] as? String ?: "",
                timestampMillis = payload["dateMillis"] as? Long ?: System.currentTimeMillis(),
            )
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
