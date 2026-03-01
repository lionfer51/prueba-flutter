package com.example.maps_notification_bridge

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class MapsNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val extras = sbn.notification.extras
        val title = extras?.getCharSequence("android.title")?.toString().orEmpty()
        val text = extras?.getCharSequence("android.text")?.toString().orEmpty()

        NotificationRelay.emit(
            mapOf(
                "packageName" to sbn.packageName,
                "title" to title,
                "text" to text,
            )
        )
    }
}
