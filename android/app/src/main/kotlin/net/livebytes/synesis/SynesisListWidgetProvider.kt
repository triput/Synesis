package net.livebytes.synesis

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

/** Account-scoped scrollable mail list widget (DEF-044). */
class SynesisListWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            WidgetConfigStore.delete(context, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val accountId = WidgetConfigStore.loadAccountId(context, appWidgetId)
            val folderId = WidgetConfigStore.loadFolderId(context, appWidgetId)
            if (accountId.isNullOrBlank() || folderId.isNullOrBlank()) {
                return
            }

            val theme = WidgetSnapshotReader.readTheme(
                WidgetSnapshotReader.readCounterJson(context),
            )
            val accountLabel = WidgetConfigStore.loadAccountLabel(context, appWidgetId)
                ?: accountId
            val folderName = WidgetConfigStore.loadFolderName(context, appWidgetId)
                ?: "Inbox"

            val views = RemoteViews(context.packageName, R.layout.synesis_list_widget)
            views.setInt(R.id.list_widget_root, "setBackgroundColor", theme.ink)
            views.setTextViewText(R.id.list_widget_title, accountLabel)
            views.setTextColor(R.id.list_widget_title, theme.text)
            views.setTextViewText(R.id.list_widget_subtitle, folderName)
            views.setTextColor(R.id.list_widget_subtitle, theme.teal)

            val serviceIntent = Intent(context, SynesisListWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.list_widget_list, serviceIntent)
            views.setEmptyView(R.id.list_widget_list, R.id.list_widget_empty)

            val templateIntent = Intent(context, MainActivity::class.java)
            val clickPendingIntent = android.app.PendingIntent.getActivity(
                context,
                appWidgetId,
                templateIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                    android.app.PendingIntent.FLAG_MUTABLE,
            )
            views.setPendingIntentTemplate(R.id.list_widget_list, clickPendingIntent)

            views.setOnClickPendingIntent(
                R.id.list_widget_header,
                MainActivity.widgetIntent(
                    context = context,
                    action = "open_inbox",
                    accountId = accountId,
                    folderId = folderId,
                    requestCode = appWidgetId * 10 + 2,
                ),
            )

            views.setOnClickPendingIntent(
                R.id.list_widget_compose,
                MainActivity.widgetIntent(
                    context = context,
                    action = "compose",
                    accountId = accountId,
                    requestCode = appWidgetId * 10 + 1,
                ),
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(
                appWidgetId,
                R.id.list_widget_list,
            )
        }

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, SynesisListWidgetProvider::class.java),
            )
            for (appWidgetId in ids) {
                updateWidget(context, manager, appWidgetId)
            }
        }
    }
}
