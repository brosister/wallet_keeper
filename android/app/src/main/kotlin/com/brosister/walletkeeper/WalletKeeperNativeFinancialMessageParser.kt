package com.brosister.walletkeeper

import android.content.Context

data class NativeFinancialMessage(
    val title: String,
    val amountText: String,
)

object WalletKeeperNativeFinancialMessageParser {
    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
    private const val CURRENCY_PREF_KEY = "flutter.wallet_keeper_currency_v1"

    private val requiredKeywords =
        listOf(
            "입금",
            "출금",
            "승인",
            "결제",
            "자동이체",
            "이체",
            "환불",
            "카드대금",
            "청구금액",
            "결제예정금액",
            "출금예정",
            "납부",
        )

    private val marketingKeywords =
        listOf(
            "이벤트",
            "문의",
            "회원권",
            "개월",
            "등록 가능",
            "금액인상",
            "vat",
            "상담",
            "혜택",
            "프로모션",
            "등로",
        )

    fun parse(context: Context, body: String): NativeFinancialMessage? {
        val currency = currentCurrency(context)
        val amountPattern = Regex(
            """(?:${currencyRegex(currency)}\s*([0-9][0-9,]*)|([0-9][0-9,]*)\s*${currencyRegex(currency)})"""
        )
        val normalized = body
            .replace('\n', ' ')
            .replace(Regex("""\s+"""), " ")
            .trim()
        val amountMatch = amountPattern.find(normalized) ?: return null
        val digits = amountMatch.groupValues[1].ifBlank { amountMatch.groupValues[2] }
        val amount = formatAmountText(currency, digits)
        val lower = normalized.lowercase()
        if (marketingKeywords.any { lower.contains(it.lowercase()) }) {
            return null
        }
        if (requiredKeywords.none { lower.contains(it.lowercase()) }) {
            return null
        }
        return NativeFinancialMessage(
            title = WalletKeeperNativeNotifierTitleResolver.resolveTitle(normalized, currency),
            amountText = amount,
        )
    }

    private fun currentCurrency(context: Context): String {
        return context
            .getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            .getString(CURRENCY_PREF_KEY, "krw")
            ?: "krw"
    }

    private fun currencyRegex(currency: String): String =
        when (currency) {
            "usd" -> """(?:USD|US\$|\$|달러)"""
            "jpy" -> """(?:JPY|¥|엔)"""
            "cny" -> """(?:CNY|CN¥|¥|위안|元|人民币)"""
            else -> """(?:원|KRW|₩)"""
        }

    private fun formatAmountText(currency: String, digits: String): String =
        when (currency) {
            "usd" -> "\$$digits"
            "jpy" -> "¥$digits"
            "cny" -> "CN¥$digits"
            else -> "${digits}원"
        }
}
