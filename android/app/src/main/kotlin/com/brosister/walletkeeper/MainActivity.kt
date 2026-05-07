package com.brosister.walletkeeper

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val MMS_READER_CHANNEL = "wallet_keeper/mms_reader"
        private const val MMS_ROUTE_CHANNEL = "wallet_keeper/mms_route"
        private const val NATIVE_NOTIFICATION_CHANNEL = "wallet_keeper/native_notifications"
        private const val NOTIFICATION_ACCESS_CHANNEL = "wallet_keeper/notification_access"
        private const val PREFS_NAME = "wallet_keeper_native"
        private const val LAUNCH_ROUTE_KEY = "launch_route"
        private const val SMS_INBOX_ROUTE = "sms_inbox"
        private const val OPEN_SMS_INBOX_ACTION = "com.brosister.walletkeeper.OPEN_SMS_INBOX"
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        storeLaunchRouteIfNeeded(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        storeLaunchRouteIfNeeded(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MMS_READER_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "queryRecentMms" -> {
                    try {
                        val recentDays = call.argument<Int>("recentDays") ?: 60
                        val limit = call.argument<Int>("limit") ?: 100
                        result.success(MmsReader.queryRecentMms(this, recentDays, limit))
                    } catch (error: Exception) {
                        result.error("mms_query_failed", error.message, null)
                    }
                }

                "consumePendingMms" -> {
                    try {
                        result.success(MmsReader.consumePendingMms(this))
                    } catch (error: Exception) {
                        result.error("mms_query_failed", error.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MMS_ROUTE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeLaunchRoute" -> {
                    result.success(consumeLaunchRoute())
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NATIVE_NOTIFICATION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "showFinancialNotification" -> {
                    try {
                        WalletKeeperNativeNotifier.showFinancialNotification(
                            context = this,
                            notificationId = call.argument<Int>("notificationId")
                                ?: System.currentTimeMillis().toInt(),
                            title = call.argument<String>("title") ?: "지갑지켜",
                            amountText = call.argument<String>("amountText") ?: "",
                            timestampMillis = call.argument<Long>("timestampMillis")
                                ?: System.currentTimeMillis(),
                        )
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("native_notification_failed", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_ACCESS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }
                "openNotificationListenerSettings" -> {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                        )
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("notification_access_settings_failed", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun storeLaunchRouteIfNeeded(intent: Intent?) {
        if (intent?.action != OPEN_SMS_INBOX_ACTION) return
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(LAUNCH_ROUTE_KEY, SMS_INBOX_ROUTE)
            .apply()
    }

    private fun consumeLaunchRoute(): String? {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val route = prefs.getString(LAUNCH_ROUTE_KEY, null)
        if (route != null) {
            prefs.edit().remove(LAUNCH_ROUTE_KEY).apply()
        }
        return route
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val enabledListeners =
            Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
        return enabledListeners.split(':').any { listener ->
            listener.contains(packageName, ignoreCase = true) &&
                listener.contains("WalletKeeperNotificationListenerService")
        }
    }
}
