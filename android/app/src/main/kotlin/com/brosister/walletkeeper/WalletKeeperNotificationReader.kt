package com.brosister.walletkeeper

import android.app.Notification
import android.content.Context
import android.os.Bundle
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

object WalletKeeperNotificationReader {
    private const val PREFS_NAME = "wallet_keeper_native"
    private const val PENDING_NOTIFICATIONS_KEY = "pending_financial_notifications"
    private const val REALTIME_SEEN_NOTIFICATION_KEYS = "realtime_seen_notification_keys"

    private val blockedPackagePrefixes = listOf(
        "com.brosister.walletkeeper",
        "com.android.systemui",
        "com.android.messaging",
        "com.google.android.apps.messaging",
        "com.samsung.android.messaging",
        "com.kakao.talk",
        "com.zhiliaoapp.musically",
        "com.ss.android.ugc.trill",
        "com.instagram.android",
        "com.facebook.katana",
        "com.google.android.youtube",
        "com.nhn.android.search",
        "com.twitter.android",
    )

    fun extractFinancialNotification(
        context: Context,
        sbn: StatusBarNotification,
    ): Map<String, Any?>? {
        val packageName = sbn.packageName ?: return null
        if (blockedPackagePrefixes.any { packageName.startsWith(it) }) return null
        if (sbn.isOngoing) return null

        val notification = sbn.notification ?: return null
        val title = buildTitle(notification.extras)?.trim().orEmpty()
        val textBody = buildTextBody(notification.extras)?.trim().orEmpty()
        val body = listOf(title, textBody).filter { it.isNotBlank() }.joinToString(" ").trim()
        if (body.isBlank()) return null
        val parsed = WalletKeeperNativeFinancialMessageParser.parse(body) ?: return null

        return mapOf(
            "id" to buildNotificationId(sbn),
            "address" to packageName,
            "body" to body,
            "titleHint" to title,
            "textBody" to textBody,
            "dateMillis" to sbn.postTime,
            "title" to parsed.title,
            "amountText" to parsed.amountText,
        )
    }

    fun shouldEnqueueRealtimeNotification(context: Context, notificationKey: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val current = prefs.getString(REALTIME_SEEN_NOTIFICATION_KEYS, null)
        val array = if (current.isNullOrBlank()) JSONArray() else JSONArray(current)
        for (i in 0 until array.length()) {
            if (array.optString(i) == notificationKey) {
                return false
            }
        }
        array.put(notificationKey)
        val trimmed = JSONArray()
        val start = maxOf(0, array.length() - 80)
        for (i in start until array.length()) {
            trimmed.put(array.optString(i))
        }
        prefs.edit().putString(REALTIME_SEEN_NOTIFICATION_KEYS, trimmed.toString()).apply()
        return true
    }

    fun storePendingNotification(context: Context, message: Map<String, Any?>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val current = prefs.getString(PENDING_NOTIFICATIONS_KEY, null)
        val array = if (current.isNullOrBlank()) JSONArray() else JSONArray(current)
        val id = message["id"] as? String ?: return
        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue
            if (item.optString("id") == id) return
        }
        val json = JSONObject()
            .put("id", id)
            .put("address", message["address"] as? String ?: "")
            .put("body", message["body"] as? String ?: "")
            .put("titleHint", message["titleHint"] as? String ?: "")
            .put("textBody", message["textBody"] as? String ?: "")
            .put("dateMillis", message["dateMillis"] as? Long ?: System.currentTimeMillis())
        array.put(json)
        prefs.edit().putString(PENDING_NOTIFICATIONS_KEY, array.toString()).apply()
    }

    fun consumePendingNotifications(context: Context): List<Map<String, Any?>> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val current = prefs.getString(PENDING_NOTIFICATIONS_KEY, null)
        if (current.isNullOrBlank()) return emptyList()
        val array = JSONArray(current)
        val items = mutableListOf<Map<String, Any?>>()
        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue
            items.add(
                mapOf(
                    "id" to item.optString("id"),
                    "address" to item.optString("address"),
                    "body" to item.optString("body"),
                    "titleHint" to item.optString("titleHint"),
                    "textBody" to item.optString("textBody"),
                    "dateMillis" to item.optLong("dateMillis"),
                )
            )
        }
        prefs.edit().remove(PENDING_NOTIFICATIONS_KEY).apply()
        return items
    }

    private fun buildNotificationId(sbn: StatusBarNotification): String {
        return "app_noti_${sbn.packageName}_${sbn.id}_${sbn.postTime}"
    }

    private fun buildTitle(extras: Bundle?): String? {
        if (extras == null) return null
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim().orEmpty()
        return title.ifBlank { null }
    }

    private fun buildTextBody(extras: Bundle?): String? {
        if (extras == null) return null
        val pieces = buildList<String> {
            addCharSequence(extras.getCharSequence(Notification.EXTRA_TEXT))
            addCharSequence(extras.getCharSequence(Notification.EXTRA_BIG_TEXT))
            addCharSequence(extras.getCharSequence(Notification.EXTRA_SUB_TEXT))
            addCharSequence(extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT))
        }
        val body = pieces.joinToString(" ").replace(Regex("\\s+"), " ").trim()
        return body.ifBlank { null }
    }

    private fun MutableList<String>.addCharSequence(value: CharSequence?) {
        val text = value?.toString()?.trim().orEmpty()
        if (text.isNotEmpty()) add(text)
    }
}
