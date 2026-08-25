package com.ngelamar.app.ngelamar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews

private const val WIDGET_PREFERENCES = "ngelamar_home_widget"
private const val ACTION_OPEN_NGELAMAR = "com.ngelamar.app.ngelamar.OPEN_FROM_WIDGET"

internal object NgelamarWidgetStorage {
    private const val KEY_KIND = "kind"
    private const val KEY_LABEL = "label"
    private const val KEY_TITLE = "title"
    private const val KEY_SUBTITLE = "subtitle"
    private const val KEY_DETAIL = "detail"
    private const val KEY_JOB_ID = "job_id"
    private const val KEY_ACTIVE_COUNT = "active_count"
    private const val KEY_HAS_CONTENT = "has_content"

    fun save(context: Context, payload: Map<*, *>) {
        context.getSharedPreferences(WIDGET_PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_KIND, payload["kind"].asSafeString())
            .putString(KEY_LABEL, payload["label"].asSafeString())
            .putString(KEY_TITLE, payload["title"].asSafeString())
            .putString(KEY_SUBTITLE, payload["subtitle"].asSafeString())
            .putString(KEY_DETAIL, payload["detail"].asSafeString())
            .putString(KEY_JOB_ID, payload["jobId"].asSafeString())
            .putInt(KEY_ACTIVE_COUNT, (payload["activeCount"] as? Number)?.toInt() ?: 0)
            .putBoolean(KEY_HAS_CONTENT, payload["hasContent"] as? Boolean ?: false)
            .apply()
    }

    fun read(context: Context): NgelamarWidgetData {
        val preferences = context.getSharedPreferences(WIDGET_PREFERENCES, Context.MODE_PRIVATE)
        return NgelamarWidgetData(
            kind = preferences.getString(KEY_KIND, "empty") ?: "empty",
            label = preferences.getString(KEY_LABEL, "NGELAMAR") ?: "NGELAMAR",
            title = preferences.getString(KEY_TITLE, "Semua pengingat aman") ?: "Semua pengingat aman",
            subtitle = preferences.getString(
                KEY_SUBTITLE,
                "Belum ada interview atau tindakan yang akan datang.",
            ) ?: "Belum ada interview atau tindakan yang akan datang.",
            detail = preferences.getString(
                KEY_DETAIL,
                "Buka Ngelamar untuk mencatat lamaran atau catatan baru.",
            ) ?: "Buka Ngelamar untuk mencatat lamaran atau catatan baru.",
            jobId = preferences.getString(KEY_JOB_ID, "") ?: "",
            activeCount = preferences.getInt(KEY_ACTIVE_COUNT, 0),
            hasContent = preferences.getBoolean(KEY_HAS_CONTENT, false),
        )
    }

    private fun Any?.asSafeString(): String =
        (this?.toString() ?: "").replace(Regex("\\s+"), " ").trim().take(160)
}

internal data class NgelamarWidgetData(
    val kind: String,
    val label: String,
    val title: String,
    val subtitle: String,
    val detail: String,
    val jobId: String,
    val activeCount: Int,
    val hasContent: Boolean,
)

class NgelamarReminderWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId -> render(context, appWidgetManager, appWidgetId) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_OPEN_NGELAMAR) {
            launchApp(context, intent.getStringExtra("job_id").orEmpty())
        }
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val provider = ComponentName(context, NgelamarReminderWidgetProvider::class.java)
            manager.getAppWidgetIds(provider).forEach { appWidgetId ->
                render(context, manager, appWidgetId)
            }
        }

        private fun render(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
            val data = NgelamarWidgetStorage.read(context)
            val views = RemoteViews(context.packageName, R.layout.ngelamar_reminder_widget)
            val accent = when (data.kind) {
                "interview" -> Color.rgb(92, 68, 228)
                "action" -> Color.rgb(34, 160, 107)
                "note" -> Color.rgb(217, 119, 6)
                else -> Color.rgb(92, 68, 228)
            }
            views.setTextViewText(R.id.widget_label, data.label)
            views.setTextViewText(R.id.widget_title, data.title)
            views.setTextViewText(R.id.widget_subtitle, data.subtitle)
            views.setTextViewText(R.id.widget_detail, data.detail)
            views.setTextViewText(
                R.id.widget_count,
                if (data.activeCount > 1) "+${data.activeCount - 1}" else "",
            )
            views.setViewVisibility(
                R.id.widget_count,
                if (data.activeCount > 1) View.VISIBLE else View.GONE,
            )
            views.setInt(R.id.widget_accent, "setBackgroundColor", accent)
            views.setTextColor(R.id.widget_label, accent)
            views.setContentDescription(
                R.id.widget_root,
                "${data.label}. ${data.title}. ${data.subtitle}. Ketuk untuk membuka Ngelamar.",
            )

            val openIntent = Intent(context, NgelamarReminderWidgetProvider::class.java).apply {
                action = ACTION_OPEN_NGELAMAR
                putExtra("job_id", data.jobId)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_open_button, pendingIntent)
            manager.updateAppWidget(appWidgetId, views)
        }

        private fun launchApp(context: Context, jobId: String) {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("from_home_widget", true)
                    putExtra("job_id", jobId)
                }
            if (launchIntent != null) context.startActivity(launchIntent)
        }
    }
}
