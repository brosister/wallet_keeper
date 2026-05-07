package com.brosister.walletkeeper

import android.content.Context
import android.net.Uri
import android.provider.Telephony
import org.json.JSONArray
import org.json.JSONObject

object MmsReader {
    private const val PREFS_NAME = "wallet_keeper_native"
    private const val PENDING_MMS_KEY = "pending_mms_messages"
    private const val REALTIME_SEEN_MMS_IDS_KEY = "realtime_seen_mms_ids"

    fun queryRecentMms(context: Context, recentDays: Int, limit: Int): List<Map<String, Any?>> {
        val cutoffSeconds =
            (System.currentTimeMillis() - recentDays * 24L * 60L * 60L * 1000L) / 1000L
        val uri = Telephony.Mms.Inbox.CONTENT_URI
        val projection = arrayOf(Telephony.Mms._ID, Telephony.Mms.DATE, Telephony.Mms.SUBJECT)
        val messages = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(
            uri,
            projection,
            "${Telephony.Mms.DATE} >= ?",
            arrayOf(cutoffSeconds.toString()),
            "${Telephony.Mms.DATE} DESC"
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(Telephony.Mms._ID)
            val dateIndex = cursor.getColumnIndexOrThrow(Telephony.Mms.DATE)
            while (cursor.moveToNext() && messages.size < limit) {
                val mmsId = cursor.getString(idIndex)
                val dateSeconds = cursor.getLong(dateIndex)
                val body = readMmsText(context, mmsId) ?: continue
                messages.add(
                    mapOf(
                        "id" to "mms_$mmsId",
                        "address" to readMmsAddress(context, mmsId),
                        "body" to body,
                        "dateMillis" to dateSeconds * 1000L,
                    )
                )
            }
        }
        return messages
    }

    fun storePendingMms(context: Context, message: Map<String, Any?>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val current = prefs.getString(PENDING_MMS_KEY, null)
        val array = if (current.isNullOrBlank()) JSONArray() else JSONArray(current)
        val id = message["id"] as? String ?: return
        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue
            if (item.optString("id") == id) {
                return
            }
        }
        val json = JSONObject()
            .put("id", id)
            .put("address", message["address"] as? String ?: "")
            .put("body", message["body"] as? String ?: "")
            .put("dateMillis", message["dateMillis"] as? Long ?: System.currentTimeMillis())
        array.put(json)
        prefs.edit().putString(PENDING_MMS_KEY, array.toString()).apply()
    }

    fun shouldEnqueueRealtimeMms(context: Context, message: Map<String, Any?>): Boolean {
        val id = message["id"] as? String ?: return false
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val current = prefs.getString(REALTIME_SEEN_MMS_IDS_KEY, null)
        val array = if (current.isNullOrBlank()) JSONArray() else JSONArray(current)
        for (i in 0 until array.length()) {
            if (array.optString(i) == id) {
                return false
            }
        }
        array.put(id)
        val trimmed = JSONArray()
        val start = maxOf(0, array.length() - 40)
        for (i in start until array.length()) {
            trimmed.put(array.optString(i))
        }
        prefs.edit().putString(REALTIME_SEEN_MMS_IDS_KEY, trimmed.toString()).apply()
        return true
    }

    fun consumePendingMms(context: Context): List<Map<String, Any?>> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val current = prefs.getString(PENDING_MMS_KEY, null)
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
                    "dateMillis" to item.optLong("dateMillis"),
                )
            )
        }
        prefs.edit().remove(PENDING_MMS_KEY).apply()
        return items
    }

    private fun readMmsText(context: Context, mmsId: String): String? {
        val partUri = Uri.parse("content://mms/part")
        val parts = mutableListOf<String>()
        context.contentResolver.query(
            partUri,
            arrayOf("_id", "ct", "text", "_data"),
            "mid=?",
            arrayOf(mmsId),
            null
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow("_id")
            val ctIndex = cursor.getColumnIndexOrThrow("ct")
            val textIndex = cursor.getColumnIndexOrThrow("text")
            val dataIndex = cursor.getColumnIndexOrThrow("_data")
            while (cursor.moveToNext()) {
                val contentType = cursor.getString(ctIndex) ?: continue
                if (contentType != "text/plain") continue
                val text = cursor.getString(textIndex)
                if (!text.isNullOrBlank()) {
                    parts.add(text)
                    continue
                }
                val data = cursor.getString(dataIndex)
                if (!data.isNullOrBlank()) {
                    readPartText(context, cursor.getString(idIndex))?.let(parts::add)
                }
            }
        }
        val joined = parts.joinToString("\n").trim()
        return joined.ifBlank { null }
    }

    private fun readPartText(context: Context, partId: String): String? {
        val uri = Uri.parse("content://mms/part/$partId")
        return context.contentResolver.openInputStream(uri)
            ?.bufferedReader()
            ?.use { it.readText() }
            ?.trim()
    }

    private fun readMmsAddress(context: Context, mmsId: String): String? {
        val addrUri = Uri.parse("content://mms/$mmsId/addr")
        context.contentResolver.query(
            addrUri,
            arrayOf("address", "type"),
            "type=137",
            null,
            null
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val address = cursor.getString(cursor.getColumnIndexOrThrow("address"))
                if (!address.isNullOrBlank() && address != "insert-address-token") {
                    return address
                }
            }
        }
        return null
    }
}
