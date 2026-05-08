package com.brosister.walletkeeper

data class NativeFinancialMessage(
    val title: String,
    val amountText: String,
)

object WalletKeeperNativeFinancialMessageParser {
    private val amountPattern = Regex("""([0-9][0-9,]*)\s*원""")
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
            "재등록",
        )

    fun parse(body: String): NativeFinancialMessage? {
        val normalized = body
            .replace('\n', ' ')
            .replace(Regex("""\s+"""), " ")
            .trim()
        val amountMatch = amountPattern.find(normalized) ?: return null
        val amount = "${amountMatch.groupValues[1]}원"
        val lower = normalized.lowercase()
        if (marketingKeywords.any { lower.contains(it.lowercase()) }) {
            return null
        }
        if (requiredKeywords.none { lower.contains(it.lowercase()) }) {
            return null
        }
        return NativeFinancialMessage(
            title = WalletKeeperNativeNotifierTitleResolver.resolveTitle(normalized),
            amountText = amount,
        )
    }
}
