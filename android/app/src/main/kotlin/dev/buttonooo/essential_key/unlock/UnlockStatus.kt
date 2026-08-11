package dev.buttonooo.essential_key.unlock

data class PackageState(
    val packageName: String,
    val installed: Boolean,
    val freed: Boolean
)

enum class UnlockStatus {
    FREED,
    PARTIALLY_FREED,
    LOCKED,
    NO_CONSUMERS
}
