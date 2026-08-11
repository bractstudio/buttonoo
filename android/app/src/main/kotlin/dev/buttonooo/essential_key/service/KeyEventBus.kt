package dev.buttonooo.essential_key.service

import android.view.KeyEvent
import dev.buttonooo.essential_key.core.KeyGesture
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

object KeyEventBus {
    @Volatile var learnMode: Boolean = false
    @Volatile var suppressActions: Boolean = false

    private val _rawEvents = MutableSharedFlow<RawKeyEvent>(extraBufferCapacity = 64)
    val rawEvents: SharedFlow<RawKeyEvent> = _rawEvents.asSharedFlow()

    private val _gestures = MutableSharedFlow<KeyGesture>(extraBufferCapacity = 64)
    val gestures: SharedFlow<KeyGesture> = _gestures.asSharedFlow()

    data class RawKeyEvent(
        val keyCode: Int,
        val scanCode: Int,
        val action: Int,
        val eventTime: Long
    )

    fun publishRaw(event: KeyEvent) {
        _rawEvents.tryEmit(
            RawKeyEvent(
                keyCode = event.keyCode,
                scanCode = event.scanCode,
                action = event.action,
                eventTime = event.eventTime
            )
        )
    }

    fun publishGesture(gesture: KeyGesture) {
        _gestures.tryEmit(gesture)
    }
}
