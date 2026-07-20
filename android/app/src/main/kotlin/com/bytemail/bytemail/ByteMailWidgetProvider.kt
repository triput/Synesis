package com.bytemail.bytemail

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Renders repository snapshots saved by WidgetSnapshotService.
 *
 * The provider reads SharedPreferences directly, so normal widget refreshes do
 * not create a Flutter engine or wake the ByteMail UI isolate.
 *
 * TC-11 (W7): applies theme token colors and Focused/Other unread split from
 * the counter snapshot when present; falls back to the Dark pack defaults.
 */
class ByteMailWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val counterJson = readSnapshot(context, COUNTER_KEY)
        val counter = readCounter(counterJson)
        val focused = readFocusedUnread(counterJson)
        val other = readOtherUnread(counterJson)
        val subject = readLatestSubject(context)
        val theme = readTheme(counterJson)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.byte_mail_widget)
            views.setInt(R.id.widget_root, "setBackgroundColor", theme.ink)
            views.setTextColor(R.id.widget_brand, theme.text)
            val unreadLabel = if (focused + other > 0) {
                "$counter unread · $focused focused · $other other"
            } else {
                "$counter unread"
            }
            views.setTextViewText(R.id.widget_unread_count, unreadLabel)
            views.setTextColor(R.id.widget_unread_count, theme.teal)
            views.setTextViewText(R.id.widget_latest_subject, subject)
            views.setTextColor(R.id.widget_latest_subject, theme.text)
            views.setInt(R.id.widget_open_inbox_action, "setBackgroundColor", theme.panel2)
            views.setTextColor(R.id.widget_open_inbox_action, theme.text)
            views.setInt(R.id.widget_compose_action, "setBackgroundColor", theme.indigo)
            views.setTextColor(R.id.widget_compose_action, theme.onAccent)
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

    private fun readCounter(snapshot: String?): Int {
        if (snapshot == null) return 0
        return runCatching {
            JSONObject(snapshot).optInt("unreadCount", 0)
        }.getOrDefault(0)
    }

    private fun readFocusedUnread(snapshot: String?): Int {
        if (snapshot == null) return 0
        return runCatching {
            JSONObject(snapshot).optInt("focusedUnread", 0)
        }.getOrDefault(0)
    }

    private fun readOtherUnread(snapshot: String?): Int {
        if (snapshot == null) return 0
        return runCatching {
            JSONObject(snapshot).optInt("otherUnread", 0)
        }.getOrDefault(0)
    }

    private fun readTheme(snapshot: String?): WidgetTheme {
        val defaults = WidgetTheme(
            ink = Color.parseColor("#10182D"),
            panel2 = Color.parseColor("#26354D"),
            text = Color.parseColor("#E5E7EB"),
            teal = Color.parseColor("#82E9D5"),
            indigo = Color.parseColor("#2D4FB3"),
            onAccent = Color.WHITE,
        )
        if (snapshot == null) return defaults
        return runCatching {
            val theme = JSONObject(snapshot).optJSONObject("theme") ?: return defaults
            WidgetTheme(
                ink = theme.optInt("ink", defaults.ink),
                panel2 = theme.optInt("panel2", defaults.panel2),
                text = theme.optInt("text", defaults.text),
                teal = theme.optInt("teal", defaults.teal),
                indigo = theme.optInt("indigo", defaults.indigo),
                onAccent = theme.optInt("onAccent", defaults.onAccent),
            )
        }.getOrDefault(defaults)
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

    private data class WidgetTheme(
        val ink: Int,
        val panel2: Int,
        val text: Int,
        val teal: Int,
        val indigo: Int,
        val onAccent: Int,
    )

    private companion object {
        const val LIST_KEY = "byte_mail_widget.list"
        const val COUNTER_KEY = "byte_mail_widget.counter"
    }
}
