package com.example.quietify

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioManager
import android.os.Build
import android.os.SystemClock

class MainActivity : FlutterActivity() {
    
    private val CHANNEL = "bridge"
    private val NOTIFICATION_PERMISSION_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "dndPermission" -> {
                    if (hasDndPermission()) {
                        silentMode()
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) 
                                != PackageManager.PERMISSION_GRANTED) {
                                requestPermissions(
                                    arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 
                                    NOTIFICATION_PERMISSION_CODE
                                )
                            } else {
                                startMyForegroundService()
                            }
                        } else {
                            startMyForegroundService()
                        }
                        
                        // Get duration from Flutter
                        val hours = call.argument<Int>("hours") ?: 0
                        val minutes = call.argument<Int>("minutes") ?: 0
                        
                        // Schedule unmute
                        scheduleUnmute(hours, minutes)
                        
                        result.success("silent mode activated")
                    } else {
                        openDndSettings()
                        result.success("opened")
                    }
                }

                "normalMode" -> {
                    normalMode()
                    cancelScheduledUnmute()
                    stopMyService()
                    result.success("normal mode activated")
                }

                "startForegroundTask" -> {
                    startMyForegroundService()
                    result.success("Foreground Service Activated")
                }
                
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == NOTIFICATION_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startMyForegroundService()
            } else {
                android.util.Log.w("Quietify", "Notification permission denied")
            }
        }
    }

    private fun scheduleUnmute(hours: Int, minutes: Int) {
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, UnmuteReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Calculate trigger time
        val triggerTimeMillis = System.currentTimeMillis() + 
                               (hours * 60 * 60 * 1000L) + 
                               (minutes * 60 * 1000L)

        // Set exact alarm
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerTimeMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                triggerTimeMillis,
                pendingIntent
            )
        }
    }

    private fun cancelScheduledUnmute() {
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, UnmuteReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    private fun silentMode() {
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
    }

    private fun openDndSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
        startActivity(intent)
    }
    
    private fun hasDndPermission(): Boolean {
        val notiManager = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
        return notiManager.isNotificationPolicyAccessGranted
    }

    private fun normalMode() {
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
    }
    
    private fun startMyForegroundService() {
        val intent = Intent(this, RunningService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
    
    private fun stopMyService() {
        val intent = Intent(this, RunningService::class.java)
        intent.action = RunningService.ACTION_STOP
        startService(intent)
    }
}