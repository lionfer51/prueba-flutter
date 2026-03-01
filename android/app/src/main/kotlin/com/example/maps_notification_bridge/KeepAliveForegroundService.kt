package com.example.maps_notification_bridge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class KeepAliveForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createChannelIfNeeded()
        startForeground(
            FOREGROUND_ID,
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_map)
                .setContentTitle("Maps Notification Bridge")
                .setContentText("Escuchando notificaciones de navegación en segundo plano")
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(Notification.CATEGORY_SERVICE)
                .build()
        )
        return START_STICKY
    }

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Background guard",
            NotificationManager.IMPORTANCE_LOW,
        )
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "maps_bridge_foreground_guard"
        private const val FOREGROUND_ID = 3201

        fun start(context: Context) {
            val intent = Intent(context, KeepAliveForegroundService::class.java)
            ContextCompat.startForegroundService(context, intent)
        }
    }
}
