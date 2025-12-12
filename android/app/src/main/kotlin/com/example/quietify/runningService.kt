package com.example.quietify

import android.app.Service
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class RunningService : Service() {

    companion object {
        const val ACTION_STOP = "STOP_SERVICE"
        private const val CHANNEL_ID = "my_service_channel_2"
        private const val NOTIFICATION_ID = 1
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = "Quietify Service"
            val channelDescription = "Keeps Quietify running in the background"
            val importance = NotificationManager.IMPORTANCE_DEFAULT // Changed to LOW to reduce intrusiveness
            
            val channel = NotificationChannel(CHANNEL_ID, channelName, importance).apply {
                description = channelDescription
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                stopForeground(true)
            }
            stopSelf()
            return START_NOT_STICKY
        }
 
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Quietify Active")
            .setContentText("Running in background")
            .setSmallIcon(android.R.drawable.ic_lock_silent_mode) // Better default icon
            .setPriority(NotificationCompat.PRIORITY_HIGH) // Matches channel importance
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY
    }
}