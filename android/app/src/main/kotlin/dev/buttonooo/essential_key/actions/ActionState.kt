package dev.buttonooo.essential_key.actions

data class ActionState(
    val torchOn: Boolean = false,
    val rotationLocked: Boolean = false,
    val ringerMode: Int = 2, // 2 = NORMAL, 1 = VIBRATE, 0 = SILENT
    val dndOn: Boolean = false,
    val label: String = "",
    val mediaPlaying: Boolean = false
)
