package net.livebytes.synesis

import android.content.Context

/** Persists per [appWidgetId] account/folder selection for list widgets. */
object WidgetConfigStore {
    private const val PREFS = "SynesisListWidgetConfig"

    fun save(
        context: Context,
        appWidgetId: Int,
        accountId: String,
        folderId: String,
        accountLabel: String,
        folderName: String,
    ) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(key(appWidgetId, "accountId"), accountId)
            .putString(key(appWidgetId, "folderId"), folderId)
            .putString(key(appWidgetId, "accountLabel"), accountLabel)
            .putString(key(appWidgetId, "folderName"), folderName)
            .apply()
    }

    fun loadAccountId(context: Context, appWidgetId: Int): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(key(appWidgetId, "accountId"), null)

    fun loadFolderId(context: Context, appWidgetId: Int): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(key(appWidgetId, "folderId"), null)

    fun loadAccountLabel(context: Context, appWidgetId: Int): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(key(appWidgetId, "accountLabel"), null)

    fun loadFolderName(context: Context, appWidgetId: Int): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(key(appWidgetId, "folderName"), null)

    fun delete(context: Context, appWidgetId: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(key(appWidgetId, "accountId"))
            .remove(key(appWidgetId, "folderId"))
            .remove(key(appWidgetId, "accountLabel"))
            .remove(key(appWidgetId, "folderName"))
            .apply()
    }

    fun listBridgeKey(accountId: String, folderId: String): String =
        "synesis_widget.list.$accountId.$folderId"

    private fun key(appWidgetId: Int, field: String): String =
        "widget_$appWidgetId.$field"
}
