package com.bytemail.bytemail

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Renders repository snapshots saved by WidgetSnapshotService.
 *
 * The provider reads SharedPreferences directly, so normal widget refreshes do
 * not create a Flutter engine or wake the ByteMail UI isolate.
 */
class ByteMailWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val counter = readCounter(context)
        val subject = readLatestSubject(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.byte_mail_widget)
            views.setTextViewText(R.id.widget_unread_count, "$counter unread")
            views.setTextViewText(R.id.widget_latest_subject, subject)
            views.setOnClickPendingIntent(
                R.id.widget_compose_action,
                appIntent(context, "compose"),
            )
            views.setOnClickPendingIntent(
                R.id.widget_open_inbox_action,
                appIntent(context, "open_inbox"),
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun readCounter(context: Context): Int {
        val snapshot = readSnapshot(context, COUNTER_KEY) ?: return 0
        return runCatching {
            JSONObject(snapshot).optInt("unreadCount", 0)
        }.getOrDefault(0)
    }

    private fun readLatestSubject(context: Context): String {
        val snapshot = readSnapshot(context, LIST_KEY) ?: return "No recent mail"
        return runCatching {
            val messages = JSONObject(snapshot).optJSONArray("messages")
            messages?.optJSONObject(0)?.optString("subject")
                ?.takeIf { it.isNotBlank() }
                ?: "No recent mail"
        }.getOrDefault("No recent mail")
    }

    private fun readSnapshot(context: Context, key: String): String? {
        val homeWidgetPreferences = context.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE,
        )
        return homeWidgetPreferences.getString(key, null)
            ?: context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE,
            ).getString("flutter.$key", null)
    }

    private fun appIntent(context: Context, action: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            putExtra("bytemail_widget_action", action)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            action.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private companion object {
        const val LIST_KEY = "byte_mail_widget.list"
        const val COUNTER_KEY = "byte_mail_widget.counter"
    }
}
