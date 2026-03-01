package com.example.maps_notification_bridge

import io.flutter.plugin.common.EventChannel

object NotificationRelay {
    private var sink: EventChannel.EventSink? = null

    val streamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            sink = events
        }

        override fun onCancel(arguments: Any?) {
            sink = null
        }
    }

    fun emit(event: Map<String, String>) {
        sink?.success(event)
    }
}
