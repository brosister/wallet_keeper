package com.brosister.walletkeeper

object WalletKeeperNativeNotifierTitleResolver {
    fun resolveTitle(body: String, currency: String): String {
        val amountPattern = amountPattern(currency)
        val normalized = body.replace("\n", " ").trim()
        val amountMatch = amountPattern.find(normalized)
        val beforeAmount =
            amountMatch?.let { normalized.substring(0, it.range.first).trim() } ?: normalized
        val stripped = beforeAmount
            .replace(Regex("""^\[[^\]]+\]\s*"""), "")
            .replace(Regex("""^\d{1,2}/\d{1,2}\s+\d{1,2}:\d{2}\s*"""), "")
            .replace("/", " ")
            .trim()
        return if (stripped.isBlank()) "지갑지켜" else stripped
    }

    fun resolveAmount(body: String, currency: String): String {
        val normalized = body.replace("\n", " ").trim()
        return amountPattern(currency).find(normalized)?.value ?: normalized.take(24)
    }

    private fun amountPattern(currency: String): Regex {
        val currencyRegex =
            when (currency) {
                "usd" -> """(?:USD|US\$|\$|달러)"""
                "jpy" -> """(?:JPY|¥|엔)"""
                "cny" -> """(?:CNY|CN¥|¥|위안|元|人民币)"""
                else -> """(?:원|KRW|₩)"""
            }
        return Regex(
            """(?:$currencyRegex\s*\d{1,3}(?:,\d{3})*|\d{1,3}(?:,\d{3})*\s*$currencyRegex)"""
        )
    }
}
