package com.example.quietify

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager

class UnmuteReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Unmute the device
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
        
        // Stop the foreground service
        val serviceIntent = Intent(context, RunningService::class.java)
        serviceIntent.action = RunningService.ACTION_STOP
        context.startService(serviceIntent)
    }
}