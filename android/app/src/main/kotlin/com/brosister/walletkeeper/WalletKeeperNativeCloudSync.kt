package com.brosister.walletkeeper

import android.content.Context
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

object WalletKeeperNativeCloudSync {
    fun enqueueDraft(
        context: Context,
        payload: Map<String, Any?>,
        parsed: NativeFinancialMessage,
        sourceType: String,
        sourceAppName: String = "",
        notificationTitle: String = "",
        notificationBody: String = "",
        onComplete: (() -> Unit)? = null,
    ) {
        Thread {
            try {
                val sessionRaw = context.getSharedPreferences(
                    "FlutterSharedPreferences",
                    Context.MODE_PRIVATE,
                ).getString("flutter.wallet_keeper_session_v1", null) ?: return@Thread
                val session = JSONObject(sessionRaw)
                if (session.optString("loginType") == "device") return@Thread
                val token = session.optString("token").trim()
                if (token.isEmpty()) return@Thread

                val id = payload["id"] as? String ?: return@Thread
                val body = payload["body"] as? String ?: return@Thread
                val amount = parsed.amountText
                    .replace(Regex("[^0-9.]"), "")
                    .toDoubleOrNull() ?: return@Thread
                val receivedAtMillis = payload["dateMillis"] as? Long
                    ?: System.currentTimeMillis()
                val sourceAddress = payload["address"] as? String ?: ""
                val institution = sourceAppName.ifBlank { sourceAddress }
                val isIncome = listOf("입금", "환불", "취소", "환급")
                    .any { body.contains(it, ignoreCase = true) }
                val isoDate = isoDate(receivedAtMillis)
                val draft = JSONObject()
                    .put("id", id)
                    .put("title", parsed.title)
                    .put("amount", amount)
                    .put("category", if (isIncome) "수입" else "지출")
                    .put("note", "")
                    .put("rawBody", body)
                    .put("type", if (isIncome) "income" else "expense")
                    .put("date", isoDate)
                    .put("sourceAddress", sourceAddress)
                    .put("sourceType", sourceType)
                    .put("institution", institution)
                    .put("eventType", parsed.title)
                    .put("matchedRule", "native_financial_notification")
                    .put("sourceAppIconBase64", "")
                    .put("sourceAppName", sourceAppName)
                    .put("sourceNotificationTitle", notificationTitle)
                    .put("sourceNotificationBody", notificationBody.ifBlank { body })
                    .put("sourceReceivedAt", isoDate)
                postDraft(token, draft)
            } catch (_: Exception) {
                // The native queue remains available for Flutter to retry on resume.
            } finally {
                onComplete?.invoke()
            }
        }.start()
    }

    private fun postDraft(token: String, draft: JSONObject) {
        val requestBody = JSONObject().put("draft", draft).toString()
        val connection = URL(
            "https://app-master.officialsite.kr/api/wallet-keeper/drafts",
        ).openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.connectTimeout = 4_000
        connection.readTimeout = 4_000
        connection.doOutput = true
        connection.setRequestProperty("Content-Type", "application/json")
        connection.setRequestProperty("Authorization", "Bearer $token")
        connection.outputStream.use { output ->
            output.write(requestBody.toByteArray(Charsets.UTF_8))
        }
        val responseStream = if (connection.responseCode in 200..299) {
            connection.inputStream
        } else {
            connection.errorStream
        }
        responseStream?.use { it.readBytes() }
        connection.disconnect()
    }

    private fun isoDate(timestampMillis: Long): String {
        return SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }.format(Date(timestampMillis))
    }
}
