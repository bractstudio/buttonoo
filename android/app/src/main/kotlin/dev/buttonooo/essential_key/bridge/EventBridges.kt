package dev.buttonooo.essential_key.bridge

import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch

class FlowEventStreamHandler<T>(
    private val scope: CoroutineScope,
    private val flow: SharedFlow<T>,
    private val mapper: (T) -> Any?
) : EventChannel.StreamHandler {

    private var job: Job? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        job = scope.launch(Dispatchers.Main) {
            flow.collect { item ->
                events?.success(mapper(item))
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        job?.cancel()
        job = null
    }
}
