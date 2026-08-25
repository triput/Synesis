package net.livebytes.synesis

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject

/** Per-widget account picker shown when pinning a list widget instance. */
class SynesisListWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private val accountEntries = mutableListOf<AccountEntry>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.synesis_list_widget_configure)
        loadAccounts()
        val listView = findViewById<ListView>(R.id.configure_account_list)
        if (accountEntries.isEmpty()) {
            listView.adapter = ArrayAdapter(
                this,
                android.R.layout.simple_list_item_1,
                listOf("Open Synesis once to load accounts"),
            )
            listView.isEnabled = false
            return
        }

        listView.adapter = object : ArrayAdapter<AccountEntry>(
            this,
            android.R.layout.simple_list_item_2,
            android.R.id.text1,
            accountEntries,
        ) {
            override fun getView(
                position: Int,
                convertView: View?,
                parent: android.view.ViewGroup,
            ): View {
                val view = super.getView(position, convertView, parent)
                val entry = accountEntries[position]
                view.findViewById<TextView>(android.R.id.text1).text = entry.label
                view.findViewById<TextView>(android.R.id.text2).text = entry.address
                return view
            }
        }
        listView.onItemClickListener = AdapterView.OnItemClickListener { _, _, position, _ ->
            val entry = accountEntries[position]
            val folderId = "inbox-${entry.id}"
            WidgetConfigStore.save(
                context = this,
                appWidgetId = appWidgetId,
                accountId = entry.id,
                folderId = folderId,
                accountLabel = entry.label,
                folderName = "Inbox",
            )
            val manager = AppWidgetManager.getInstance(this)
            SynesisListWidgetProvider.updateWidget(this, manager, appWidgetId)
            val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            setResult(RESULT_OK, result)
            finish()
        }
    }

    private fun loadAccounts() {
        accountEntries.clear()
        val snapshot = WidgetSnapshotReader.readAccountsJson(this) ?: return
        runCatching {
            val accounts = JSONObject(snapshot).optJSONArray("accounts") ?: JSONArray()
            for (index in 0 until accounts.length()) {
                val item = accounts.optJSONObject(index) ?: continue
                val id = item.optString("id")
                if (id.isBlank()) {
                    continue
                }
                accountEntries.add(
                    AccountEntry(
                        id = id,
                        label = item.optString("label", id),
                        address = item.optString("address", ""),
                    ),
                )
            }
        }
    }

    private data class AccountEntry(
        val id: String,
        val label: String,
        val address: String,
    ) {
        override fun toString(): String = label
    }
}
