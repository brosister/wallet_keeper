package com.brosister.walletkeeper

object WalletKeeperNativeNotifierTitleResolver {
    private val amountPattern = Regex("""\b\d{1,3}(?:,\d{3})*원""")

    fun resolveTitle(body: String): String {
        val normalized = body.replace("\n", " ").trim()
        val amountMatch = amountPattern.find(normalized)
        val beforeAmount = amountMatch?.let { normalized.substring(0, it.range.first).trim() } ?: normalized
        val stripped = beforeAmount
            .replace(Regex("""^\[[^\]]+\]\s*"""), "")
            .replace(Regex("""^\d{1,2}/\d{1,2}\s+\d{1,2}:\d{2}\s*"""), "")
            .replace("/", " ")
            .trim()
        return if (stripped.isBlank()) "지갑지켜" else stripped
    }

    fun resolveAmount(body: String): String {
        val normalized = body.replace("\n", " ").trim()
        return amountPattern.find(normalized)?.value ?: normalized.take(24)
    }
}
