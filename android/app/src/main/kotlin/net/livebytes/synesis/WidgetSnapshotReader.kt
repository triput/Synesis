package net.livebytes.synesis

import android.content.Context
import org.json.JSONObject

/** Reads Flutter-written widget snapshot JSON from SharedPreferences. */
object WidgetSnapshotReader {
    fun read(context: Context, key: String): String? {
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

    fun readAccountsJson(context: Context): String? =
        read(context, "synesis_widget.accounts")

    fun readCounterJson(context: Context): String? =
        read(context, "synesis_widget.counter")

    fun readListJson(context: Context): String? =
        read(context, "synesis_widget.list")

    fun readTheme(snapshot: String?): WidgetTheme {
        val defaults = WidgetTheme(
            ink = android.graphics.Color.parseColor("#10182D"),
            panel = android.graphics.Color.parseColor("#1A2332"),
            panel2 = android.graphics.Color.parseColor("#26354D"),
            text = android.graphics.Color.parseColor("#E5E7EB"),
            muted = android.graphics.Color.parseColor("#9CA3AF"),
            teal = android.graphics.Color.parseColor("#82E9D5"),
            indigo = android.graphics.Color.parseColor("#2D4FB3"),
            onAccent = android.graphics.Color.WHITE,
        )
        if (snapshot == null) {
            return defaults
        }
        return runCatching {
            val theme = JSONObject(snapshot).optJSONObject("theme") ?: return defaults
            WidgetTheme(
                ink = theme.optInt("ink", defaults.ink),
                panel = theme.optInt("panel", defaults.panel),
                panel2 = theme.optInt("panel2", defaults.panel2),
                text = theme.optInt("text", defaults.text),
                muted = theme.optInt("muted", defaults.muted),
                teal = theme.optInt("teal", defaults.teal),
                indigo = theme.optInt("indigo", defaults.indigo),
                onAccent = theme.optInt("onAccent", defaults.onAccent),
            )
        }.getOrDefault(defaults)
    }
}

data class WidgetTheme(
    val ink: Int,
    val panel: Int,
    val panel2: Int,
    val text: Int,
    val muted: Int,
    val teal: Int,
    val indigo: Int,
    val onAccent: Int,
)
