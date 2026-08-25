package net.livebytes.synesis

import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class SynesisListWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        ListRemoteViewsFactory(applicationContext, intent)
}

private class ListRemoteViewsFactory(
    private val context: android.content.Context,
    intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {
    private val appWidgetId = intent.getIntExtra(
        android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID,
        android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID,
    )
    private val rows = mutableListOf<MailRow>()
    private var theme = WidgetSnapshotReader.readTheme(null)

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        rows.clear()
        theme = WidgetSnapshotReader.readTheme(
            WidgetSnapshotReader.readCounterJson(context),
        )
        val accountId = WidgetConfigStore.loadAccountId(context, appWidgetId)
        val folderId = WidgetConfigStore.loadFolderId(context, appWidgetId)
        if (accountId.isNullOrBlank() || folderId.isNullOrBlank()) {
            return
        }
        val snapshot = WidgetSnapshotReader.read(
            context,
            WidgetConfigStore.listBridgeKey(accountId, folderId),
        ) ?: return
        runCatching {
            val messages = JSONObject(snapshot).optJSONArray("messages") ?: JSONArray()
            for (index in 0 until messages.length()) {
                val item = messages.optJSONObject(index) ?: continue
                rows.add(
                    MailRow(
                        id = item.optString("id"),
                        accountId = item.optString("accountId", accountId),
                        folderId = item.optString("folderId", folderId),
                        from = item.optString("from").ifBlank { "Unknown" },
                        subject = item.optString("subject").ifBlank { "(No subject)" },
                        snippet = item.optString("snippet"),
                        whenLabel = item.optString("when"),
                        unread = item.optBoolean("unread", false),
                    ),
                )
            }
        }
    }

    override fun onDestroy() {
        rows.clear()
    }

    override fun getCount(): Int = rows.size

    override fun getViewAt(position: Int): RemoteViews {
        val row = rows[position]
        val views = RemoteViews(context.packageName, R.layout.synesis_list_widget_row)
        views.setTextViewText(R.id.list_widget_row_from, row.from)
        views.setTextViewText(R.id.list_widget_row_subject, row.subject)
        views.setTextViewText(R.id.list_widget_row_snippet, row.snippet)
        views.setTextViewText(R.id.list_widget_row_when, row.whenLabel)
        val fromColor = if (row.unread) theme.teal else theme.text
        val subjectColor = if (row.unread) theme.text else theme.muted
        views.setTextColor(R.id.list_widget_row_from, fromColor)
        views.setTextColor(R.id.list_widget_row_subject, subjectColor)
        views.setTextColor(R.id.list_widget_row_snippet, theme.muted)
        views.setTextColor(R.id.list_widget_row_when, theme.muted)

        val fillInIntent = Intent().apply {
            putExtra(MainActivity.EXTRA_WIDGET_ACTION, "open_message")
            putExtra(MainActivity.EXTRA_ACCOUNT_ID, row.accountId)
            putExtra(MainActivity.EXTRA_FOLDER_ID, row.folderId)
            putExtra(MainActivity.EXTRA_MESSAGE_ID, row.id)
        }
        views.setOnClickFillInIntent(R.id.list_widget_row_root, fillInIntent)
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = rows[position].id.hashCode().toLong()

    override fun hasStableIds(): Boolean = true
}

private data class MailRow(
    val id: String,
    val accountId: String,
    val folderId: String,
    val from: String,
    val subject: String,
    val snippet: String,
    val whenLabel: String,
    val unread: Boolean,
)
