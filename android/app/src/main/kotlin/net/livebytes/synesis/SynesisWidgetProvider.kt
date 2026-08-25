package net.livebytes.synesis

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Renders repository snapshots saved by WidgetSnapshotService.
 *
 * The provider reads SharedPreferences directly, so normal widget refreshes do
 * not create a Flutter engine or wake the Synesis UI isolate.
 */
class SynesisWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val counterJson = WidgetSnapshotReader.readCounterJson(context)
        val counter = readCounter(counterJson)
        val focused = readFocusedUnread(counterJson)
        val other = readOtherUnread(counterJson)
        val subject = readLatestSubject(context)
        val theme = WidgetSnapshotReader.readTheme(counterJson)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.synesis_widget)
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
                MainActivity.widgetIntent(
                    context = context,
                    action = "compose",
                    requestCode = "compose".hashCode(),
                ),
            )
            views.setOnClickPendingIntent(
                R.id.widget_open_inbox_action,
                MainActivity.widgetIntent(
                    context = context,
                    action = "open_inbox",
                    requestCode = "open_inbox".hashCode(),
                ),
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

    private fun readLatestSubject(context: Context): String {
        val snapshot = WidgetSnapshotReader.readListJson(context) ?: return "No recent mail"
        return runCatching {
            val messages = JSONObject(snapshot).optJSONArray("messages")
            messages?.optJSONObject(0)?.optString("subject")
                ?.takeIf { it.isNotBlank() }
                ?: "No recent mail"
        }.getOrDefault("No recent mail")
    }
}
