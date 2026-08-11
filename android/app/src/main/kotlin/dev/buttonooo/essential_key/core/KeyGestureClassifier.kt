package dev.buttonooo.essential_key.core

data class GestureTiming(
    val longPressMs: Long = 500L,
    val multiTapMs: Long = 400L
)

class KeyGestureClassifier(
    private val enabledGestures: Set<KeyGesture>,
    private val timing: GestureTiming,
    private val scheduler: GestureScheduler,
    private val onGesture: (KeyGesture) -> Unit
) {
    private var tapCount = 0
    private var pressInProgress = false
    private var longTimer: Cancellable? = null
    private var tapTimer: Cancellable? = null

    fun onKeyDown() {
        cancelTapTimer()
        pressInProgress = true
        longTimer = scheduler.schedule(timing.longPressMs) {
            pressInProgress = false
            emitAndReset(KeyGesture.LONG_PRESS)
        }
    }

    fun onKeyUp() {
        if (!pressInProgress) return
        pressInProgress = false
        cancelLongTimer()
        tapCount = (tapCount + 1).coerceAtMost(4)
        val immediate = immediateOrNull()
        if (immediate != null) {
            emitAndReset(immediate)
        } else {
            tapTimer = scheduler.schedule(timing.multiTapMs) {
                emitAndReset(forTapCount(tapCount))
            }
        }
    }

    private fun immediateOrNull(): KeyGesture? {
        val double = KeyGesture.DOUBLE_PRESS in enabledGestures
        val triple = KeyGesture.TRIPLE_PRESS in enabledGestures
        val quad = KeyGesture.QUADRUPLE_PRESS in enabledGestures
        return when (tapCount) {
            4 -> KeyGesture.QUADRUPLE_PRESS
            3 -> if (!quad) KeyGesture.TRIPLE_PRESS else null
            2 -> if (!triple && !quad) KeyGesture.DOUBLE_PRESS else null
            1 -> if (!double && !triple && !quad) KeyGesture.SINGLE_PRESS else null
            else -> null
        }
    }

    private fun forTapCount(count: Int): KeyGesture = when (count) {
        1 -> KeyGesture.SINGLE_PRESS
        2 -> KeyGesture.DOUBLE_PRESS
        3 -> KeyGesture.TRIPLE_PRESS
        4 -> KeyGesture.QUADRUPLE_PRESS
        else -> KeyGesture.QUADRUPLE_PRESS
    }

    private fun emitAndReset(gesture: KeyGesture) {
        onGesture(gesture)
        reset()
    }

    private fun cancelLongTimer() {
        longTimer?.cancel()
        longTimer = null
    }

    private fun cancelTapTimer() {
        tapTimer?.cancel()
        tapTimer = null
    }

    fun reset() {
        cancelLongTimer()
        cancelTapTimer()
        tapCount = 0
        pressInProgress = false
    }
}
