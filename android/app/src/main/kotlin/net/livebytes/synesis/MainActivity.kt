package net.livebytes.synesis

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingLaunch: HashMap<String, String?>? = null
    private var launchChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launchChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LAUNCH_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumePendingLaunch" -> {
                        result.success(pendingLaunch)
                        pendingLaunch = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureIntent(intent)
    }

    private fun captureIntent(intent: Intent?) {
        if (intent == null) {
            return
        }
        val action = intent.getStringExtra(EXTRA_WIDGET_ACTION) ?: return
        pendingLaunch = hashMapOf(
            "action" to action,
            "accountId" to intent.getStringExtra(EXTRA_ACCOUNT_ID),
            "folderId" to intent.getStringExtra(EXTRA_FOLDER_ID),
            "messageId" to intent.getStringExtra(EXTRA_MESSAGE_ID),
        )
    }

    companion object {
        const val LAUNCH_CHANNEL = "net.livebytes.synesis/widget_launch"
        const val EXTRA_WIDGET_ACTION = "synesis_widget_action"
        const val EXTRA_ACCOUNT_ID = "synesis_account_id"
        const val EXTRA_FOLDER_ID = "synesis_folder_id"
        const val EXTRA_MESSAGE_ID = "synesis_message_id"

        fun widgetIntent(
            context: android.content.Context,
            action: String,
            accountId: String? = null,
            folderId: String? = null,
            messageId: String? = null,
            requestCode: Int,
        ): android.app.PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                putExtra(EXTRA_WIDGET_ACTION, action)
                if (!accountId.isNullOrBlank()) {
                    putExtra(EXTRA_ACCOUNT_ID, accountId)
                }
                if (!folderId.isNullOrBlank()) {
                    putExtra(EXTRA_FOLDER_ID, folderId)
                }
                if (!messageId.isNullOrBlank()) {
                    putExtra(EXTRA_MESSAGE_ID, messageId)
                }
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return android.app.PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                    android.app.PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
