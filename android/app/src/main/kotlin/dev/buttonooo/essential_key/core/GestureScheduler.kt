package dev.buttonooo.essential_key.core

import android.os.Handler

interface Cancellable {
    fun cancel()
}

interface GestureScheduler {
    fun schedule(delayMs: Long, action: () -> Unit): Cancellable
}

class HandlerGestureScheduler(private val handler: Handler) : GestureScheduler {
    override fun schedule(delayMs: Long, action: () -> Unit): Cancellable {
        val runnable = Runnable { action() }
        handler.postDelayed(runnable, delayMs)
        return object : Cancellable {
            override fun cancel() {
                handler.removeCallbacks(runnable)
            }
        }
    }
}
