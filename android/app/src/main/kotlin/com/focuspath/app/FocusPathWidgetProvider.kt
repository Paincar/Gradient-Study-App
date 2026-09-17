package com.focuspath.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class FocusPathWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "focuspath_widget_prefs"
        private const val KEY_STREAK = "widget_streak"
        private const val KEY_FOCUS_MINUTES = "widget_focus_minutes"
        private const val KEY_NEXT_SUBJECT = "widget_next_subject"

        fun updateWidgetData(context: Context, streak: Int, focusMinutes: Int, nextSubject: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putInt(KEY_STREAK, streak)
                .putInt(KEY_FOCUS_MINUTES, focusMinutes)
                .putString(KEY_NEXT_SUBJECT, nextSubject)
                .apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, FocusPathWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId, streak, focusMinutes, nextSubject)
            }
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            streak: Int,
            focusMinutes: Int,
            nextSubject: String
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_focus_path)

            // Update texts
            views.setTextViewText(R.id.widget_streak_text, "🔥 $streak ${if (streak == 1) "Day" else "Days"}")

            val hours = focusMinutes / 60
            val mins = focusMinutes % 60
            val timeFormatted = if (hours > 0) "${hours}h ${mins}m" else "${mins}m"
            views.setTextViewText(R.id.widget_focus_text, "⏱️ $timeFormatted")

            views.setTextViewText(R.id.widget_subject_text, "🎯 $nextSubject")

            // Tap on widget opens FocusPath MainActivity
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val streak = prefs.getInt(KEY_STREAK, 1)
        val focusMinutes = prefs.getInt(KEY_FOCUS_MINUTES, 0)
        val nextSubject = prefs.getString(KEY_NEXT_SUBJECT, "Tap to resume SPPU study session") ?: "Tap to resume SPPU study session"

        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId, streak, focusMinutes, nextSubject)
        }
    }
}
