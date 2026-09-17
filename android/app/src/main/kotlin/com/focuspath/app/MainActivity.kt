package com.focuspath.app

import android.app.AlarmManager
import android.app.AppOpsManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.CalendarContract
import android.provider.Settings
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.focuspath.app/native"

    companion object {
        const val REMINDER_CHANNEL_ID = "focuspath_study_reminders"
        const val TIMER_CHANNEL_ID = "focuspath_timer"
        const val DISTRACTION_CHANNEL_ID = "focuspath_distraction_alerts"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannels()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val id = call.argument<Int>("id") ?: 1001
                    val title = call.argument<String>("title") ?: "Gradient Notification"
                    val body = call.argument<String>("body") ?: ""
                    val channelId = call.argument<String>("channelId") ?: REMINDER_CHANNEL_ID
                    showSystemNotification(id, title, body, channelId)
                    result.success(true)
                }
                "scheduleAlarm" -> {
                    val id = call.argument<Int>("id") ?: 2001
                    val title = call.argument<String>("title") ?: "Study Reminder"
                    val body = call.argument<String>("body") ?: "Time for your study block!"
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: (System.currentTimeMillis() + 60000)
                    scheduleAlarmReminder(id, title, body, triggerAtMillis)
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    cancelAlarmReminder(id)
                    result.success(true)
                }
                "checkUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "openUsageAccessSettings" -> {
                    openUsageSettings()
                    result.success(true)
                }
                "checkDistractionUsage" -> {
                    val appNames = call.argument<List<String>>("appNames") ?: emptyList()
                    val thresholdMinutes = call.argument<Int>("thresholdMinutes") ?: 15
                    val stats = getDistractionUsage(appNames, thresholdMinutes)
                    result.success(stats)
                }
                "getInstalledApps" -> {
                    val apps = getInstalledApps()
                    result.success(apps)
                }
                "checkOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "openOverlaySettings" -> {
                    openOverlaySettings()
                    result.success(true)
                }
                "addCalendarEvent" -> {
                    val title = call.argument<String>("title") ?: "SPPU Study Session"
                    val description = call.argument<String>("description") ?: ""
                    val location = call.argument<String>("location") ?: "Study Zone"
                    val startTime = call.argument<Long>("startTimeMillis") ?: System.currentTimeMillis()
                    val endTime = call.argument<Long>("endTimeMillis") ?: (System.currentTimeMillis() + 3600000)
                    addCalendarEvent(title, description, location, startTime, endTime)
                    result.success(true)
                }
                "updateWidget" -> {
                    val streak = call.argument<Int>("streak") ?: 1
                    val focusMinutes = call.argument<Int>("focusMinutes") ?: 0
                    val nextSubject = call.argument<String>("nextSubject") ?: "Tap to resume SPPU study session"
                    FocusPathWidgetProvider.updateWidgetData(this, streak, focusMinutes, nextSubject)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val channels = listOf(
                NotificationChannel(
                    REMINDER_CHANNEL_ID,
                    "Study Reminders & Timetable",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Reminders for scheduled SPPU study sessions and timetable slots"
                    enableVibration(true)
                },
                NotificationChannel(
                    TIMER_CHANNEL_ID,
                    "Focus Timer & Breaks",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifications for Pomodoro focus timer and break transitions"
                    enableVibration(true)
                },
                NotificationChannel(
                    DISTRACTION_CHANNEL_ID,
                    "Distraction Shield Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Alerts when you exceed social media/distraction limits during study sessions"
                    enableVibration(true)
                }
            )

            for (ch in channels) {
                notificationManager.createNotificationChannel(ch)
            }
        }
    }

    private fun showSystemNotification(id: Int, title: String, body: String, channelId: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            id,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val iconRes = when (channelId) {
            DISTRACTION_CHANNEL_ID -> android.R.drawable.ic_dialog_alert
            TIMER_CHANNEL_ID -> android.R.drawable.ic_media_play
            else -> android.R.drawable.ic_lock_idle_alarm
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(iconRes)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(id, notification)
    }

    private fun scheduleAlarmReminder(id: Int, title: String, body: String, triggerAtMillis: Long) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.focuspath.app.STUDY_ALARM"
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        } catch (e: SecurityException) {
            // Fallback if exact alarm permission is restricted
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        }
    }

    private fun cancelAlarmReminder(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.focuspath.app.STUDY_ALARM"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_NO_CREATE or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(id)
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun openOverlaySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            ).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            try {
                startActivity(intent)
            } catch (e: Exception) {
                // Fallback to general overlay settings
                startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                })
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = pm.queryIntentActivities(mainIntent, 0)
        val appList = mutableListOf<Map<String, String>>()
        val seen = mutableSetOf<String>()

        for (info in resolveInfos) {
            val pkg = info.activityInfo.packageName
            if (pkg == packageName || seen.contains(pkg)) continue
            seen.add(pkg)
            val name = info.loadLabel(pm).toString()
            appList.add(mapOf("name" to name, "packageName" to pkg))
        }
        return appList.sortedBy { (it["name"] ?: "").lowercase() }
    }

    private fun addCalendarEvent(
        title: String,
        description: String,
        location: String,
        startTimeMillis: Long,
        endTimeMillis: Long
    ) {
        val intent = Intent(Intent.ACTION_INSERT).apply {
            data = CalendarContract.Events.CONTENT_URI
            putExtra(CalendarContract.Events.TITLE, title)
            putExtra(CalendarContract.Events.DESCRIPTION, description)
            putExtra(CalendarContract.Events.EVENT_LOCATION, location)
            putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startTimeMillis)
            putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endTimeMillis)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    private fun getDistractionUsage(targetAppNames: List<String>, thresholdMinutes: Int): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        result["permissionGranted"] = hasUsageStatsPermission()

        if (!hasUsageStatsPermission()) {
            result["totalMinutes"] = 0
            result["exceededThreshold"] = false
            result["mostUsedApp"] = ""
            return result
        }

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = Calendar.getInstance()
        val endTime = cal.timeInMillis
        cal.add(Calendar.HOUR_OF_DAY, -3) // Query last 3 hours
        val startTime = cal.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        // Common package mapping for popular apps
        val packageMap = mapOf(
            "Instagram" to listOf("com.instagram.android"),
            "YouTube" to listOf("com.google.android.youtube"),
            "Snapchat" to listOf("com.snapchat.android"),
            "Reddit" to listOf("com.reddit.frontpage"),
            "Netflix" to listOf("com.netflix.mediaclient"),
            "WhatsApp" to listOf("com.whatsapp"),
            "Discord" to listOf("com.discord"),
            "Twitter / X" to listOf("com.twitter.android"),
            "Telegram" to listOf("org.telegram.messenger"),
            "TikTok" to listOf("com.zhiliaoapp.musically", "com.ss.android.ugc.trill"),
            "Mobile Games" to listOf("com.pubg.imobile", "com.dts.freefireth", "com.activision.callofduty.shooter")
        )

        var totalTimeMillis = 0L
        var maxApp = ""
        var maxAppMillis = 0L

        if (stats != null) {
            for (usage in stats) {
                val pkg = usage.packageName
                for (appName in targetAppNames) {
                    val packages = packageMap[appName] ?: emptyList()
                    val isMatch = packages.contains(pkg) ||
                            pkg.equals(appName, ignoreCase = true) ||
                            (appName.length > 3 && pkg.contains(appName.lowercase().replace(" ", "")))

                    if (isMatch) {
                        val time = usage.totalTimeInForeground
                        totalTimeMillis += time
                        if (time > maxAppMillis) {
                            maxAppMillis = time
                            maxApp = appName
                        }
                    }
                }
            }
        }

        val totalMinutes = (totalTimeMillis / 60000).toInt()
        val exceeded = totalMinutes >= thresholdMinutes

        result["totalMinutes"] = totalMinutes
        result["exceededThreshold"] = exceeded
        result["mostUsedApp"] = maxApp

        if (exceeded && maxApp.isNotEmpty()) {
            showSystemNotification(
                3001,
                "⚠️ Focus Alert: $maxApp Usage Exceeded",
                "You've spent $totalMinutes min on distracting apps today. Your SPPU syllabus targets are waiting! 🎯",
                DISTRACTION_CHANNEL_ID
            )
        }

        return result
    }
}
