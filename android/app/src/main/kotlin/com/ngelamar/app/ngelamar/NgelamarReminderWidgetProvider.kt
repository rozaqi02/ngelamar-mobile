package com.ngelamar.app.ngelamar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews

private const val TAG = "NgelamarWidget"
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
    private const val KEY_OFFERING_COUNT = "offering_count"
    private const val KEY_RESPONSE_RATE = "response_rate"
    private const val KEY_TIME_BADGE = "time_badge"
    private const val KEY_STAGE_LABEL = "stage_label"
    private const val KEY_COMPANY_NAME = "company_name"
    private const val KEY_POSITION = "position"
    private const val KEY_ACTION_NOTE = "action_note"
    private const val KEY_MONTH_LABEL = "month_label"
    private const val KEY_AGENDA_COUNT = "agenda_count"
    private const val KEY_E1_TITLE = "event1_title"
    private const val KEY_E1_WHEN = "event1_when"
    private const val KEY_E2_TITLE = "event2_title"
    private const val KEY_E2_WHEN = "event2_when"
    private const val KEY_E3_TITLE = "event3_title"
    private const val KEY_E3_WHEN = "event3_when"

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
            .putInt(KEY_OFFERING_COUNT, (payload["offeringCount"] as? Number)?.toInt() ?: 0)
            .putString(KEY_RESPONSE_RATE, payload["responseRate"].asSafeString())
            .putString(KEY_TIME_BADGE, payload["timeBadge"].asSafeString())
            .putString(KEY_STAGE_LABEL, payload["stageLabel"].asSafeString())
            .putString(KEY_COMPANY_NAME, payload["companyName"].asSafeString())
            .putString(KEY_POSITION, payload["position"].asSafeString())
            .putString(KEY_ACTION_NOTE, payload["actionNote"].asSafeString())
            .putString(KEY_MONTH_LABEL, payload["monthLabel"].asSafeString())
            .putInt(KEY_AGENDA_COUNT, (payload["agendaCount"] as? Number)?.toInt() ?: 0)
            .putString(KEY_E1_TITLE, payload["event1Title"].asSafeString())
            .putString(KEY_E1_WHEN, payload["event1When"].asSafeString())
            .putString(KEY_E2_TITLE, payload["event2Title"].asSafeString())
            .putString(KEY_E2_WHEN, payload["event2When"].asSafeString())
            .putString(KEY_E3_TITLE, payload["event3Title"].asSafeString())
            .putString(KEY_E3_WHEN, payload["event3When"].asSafeString())
            .apply()
    }

    fun read(context: Context): NgelamarWidgetData {
        val preferences = context.getSharedPreferences(WIDGET_PREFERENCES, Context.MODE_PRIVATE)
        return NgelamarWidgetData(
            kind = preferences.getString(KEY_KIND, "empty") ?: "empty",
            label = preferences.getString(KEY_LABEL, "NGELAMAR") ?: "NGELAMAR",
            title = preferences.getString(KEY_TITLE, "Semua pengingat aman") ?: "Semua pengingat aman",
            subtitle = preferences.getString(KEY_SUBTITLE, "Belum ada agenda seleksi.") ?: "Belum ada agenda seleksi.",
            detail = preferences.getString(KEY_DETAIL, "Google Meet / Online") ?: "Google Meet / Online",
            jobId = preferences.getString(KEY_JOB_ID, "") ?: "",
            activeCount = preferences.getInt(KEY_ACTIVE_COUNT, 0),
            hasContent = preferences.getBoolean(KEY_HAS_CONTENT, false),
            offeringCount = preferences.getInt(KEY_OFFERING_COUNT, 0),
            responseRate = preferences.getString(KEY_RESPONSE_RATE, "0%") ?: "0%",
            timeBadge = preferences.getString(KEY_TIME_BADGE, "Jadwal Seleksi") ?: "Jadwal Seleksi",
            stageLabel = preferences.getString(KEY_STAGE_LABEL, "Interview HR") ?: "Interview HR",
            companyName = preferences.getString(KEY_COMPANY_NAME, "") ?: "",
            position = preferences.getString(KEY_POSITION, "") ?: "",
            actionNote = preferences.getString(KEY_ACTION_NOTE, "Pantau terus kabar rekrutmen terbaru.") ?: "Pantau terus kabar rekrutmen terbaru.",
            monthLabel = preferences.getString(KEY_MONTH_LABEL, "KALENDER") ?: "KALENDER",
            agendaCount = preferences.getInt(KEY_AGENDA_COUNT, 0),
            event1Title = preferences.getString(KEY_E1_TITLE, "") ?: "",
            event1When = preferences.getString(KEY_E1_WHEN, "") ?: "",
            event2Title = preferences.getString(KEY_E2_TITLE, "") ?: "",
            event2When = preferences.getString(KEY_E2_WHEN, "") ?: "",
            event3Title = preferences.getString(KEY_E3_TITLE, "") ?: "",
            event3When = preferences.getString(KEY_E3_WHEN, "") ?: "",
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
    val offeringCount: Int,
    val responseRate: String,
    val timeBadge: String,
    val stageLabel: String,
    val companyName: String,
    val position: String,
    val actionNote: String,
    val monthLabel: String = "KALENDER",
    val agendaCount: Int = 0,
    val event1Title: String = "",
    val event1When: String = "",
    val event2Title: String = "",
    val event2When: String = "",
    val event3Title: String = "",
    val event3When: String = "",
)

class NgelamarReminderWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            try {
                render(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                Log.e(TAG, "Error in onUpdate for widget $appWidgetId: ${e.message}", e)
            }
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        try {
            render(context, appWidgetManager, appWidgetId)
        } catch (e: Exception) {
            Log.e(TAG, "Error in onAppWidgetOptionsChanged for widget $appWidgetId: ${e.message}", e)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_OPEN_NGELAMAR) {
            val openAddJob = intent.getBooleanExtra("open_add_job", false)
            launchApp(context, intent.getStringExtra("job_id").orEmpty(), openAddJob)
        }
    }

    companion object {
        fun updateAll(context: Context) {
            try {
                val manager = AppWidgetManager.getInstance(context)
                val provider = ComponentName(context, NgelamarReminderWidgetProvider::class.java)
                manager.getAppWidgetIds(provider).forEach { appWidgetId ->
                    try {
                        render(context, manager, appWidgetId)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error rendering widget $appWidgetId in updateAll: ${e.message}", e)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in updateAll: ${e.message}", e)
            }
        }

        private fun getLayoutForSize(context: Context, manager: AppWidgetManager, appWidgetId: Int): Int {
            val options = manager.getAppWidgetOptions(appWidgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 150)

            return when {
                minWidth < 140 && minHeight < 100 -> R.layout.ngelamar_reminder_widget_1x1
                minWidth < 250 || minHeight < 140 -> R.layout.ngelamar_reminder_widget_2x2
                minHeight >= 220 -> R.layout.ngelamar_reminder_widget_4x3
                else -> R.layout.ngelamar_reminder_widget_4x2
            }
        }

        private fun render(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
            try {
                val data = NgelamarWidgetStorage.read(context)
                val layoutId = getLayoutForSize(context, manager, appWidgetId)
                val views = RemoteViews(context.packageName, layoutId)

                safeSetText(views, R.id.widget_label, data.label.ifBlank { "NGELAMAR" })
                val isCompact = layoutId == R.layout.ngelamar_reminder_widget_2x2 ||
                    layoutId == R.layout.ngelamar_reminder_widget_1x1
                val activeBadgeText = if (isCompact) {
                    "${data.activeCount} Aktif"
                } else {
                    "${data.activeCount} Lamaran Aktif"
                }
                safeSetText(views, R.id.widget_active_badge, activeBadgeText)

                if (layoutId != R.layout.ngelamar_reminder_widget_1x1) {
                    if (data.hasContent) {
                    safeSetVisibility(views, R.id.widget_active_container, View.VISIBLE)
                    safeSetVisibility(views, R.id.widget_empty_container, View.GONE)

                    safeSetText(
                        views,
                        R.id.widget_time_badge,
                        data.timeBadge.ifBlank { "Jadwal Seleksi" }
                    )
                    safeSetText(
                        views,
                        R.id.widget_stage_label,
                        data.stageLabel.ifBlank { "Interview HR" }
                    )
                    val displayCompany = data.companyName.ifBlank { data.title.ifBlank { "Nama Perusahaan" } }
                    val displayPosition = data.position.ifBlank { data.subtitle.ifBlank { "Posisi Pekerjaan" } }

                    safeSetText(views, R.id.widget_company_name, displayCompany)
                    safeSetText(views, R.id.widget_position_title, displayPosition)
                    safeSetText(
                        views,
                        R.id.widget_location_note,
                        data.detail.ifBlank { "Google Meet / Online" }
                    )

                    safeSetText(views, R.id.widget_kpi_offering_val, data.offeringCount.toString())
                    safeSetText(views, R.id.widget_kpi_response_val, data.responseRate.ifBlank { "0%" })
                    safeSetText(
                        views,
                        R.id.widget_action_note,
                        data.actionNote.ifBlank { "Pantau terus kabar rekrutmen terbaru." }
                    )
                } else {
                    safeSetVisibility(views, R.id.widget_active_container, View.GONE)
                    safeSetVisibility(views, R.id.widget_empty_container, View.VISIBLE)
                }
                }

                views.setContentDescription(
                    R.id.widget_root,
                    "Ngelamar Widget. ${data.title}. ${data.subtitle}."
                )

                // Intent 1: Open Specific Job (Hero / Root)
                val openJobIntent = Intent(context, NgelamarReminderWidgetProvider::class.java).apply {
                    action = ACTION_OPEN_NGELAMAR
                    putExtra("job_id", data.jobId)
                    putExtra("open_add_job", false)
                }
                val pendingOpenJob = PendingIntent.getBroadcast(
                    context,
                    appWidgetId * 10 + 1,
                    openJobIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                safeSetOnClick(views, R.id.widget_root, pendingOpenJob)
                safeSetOnClick(views, R.id.widget_hero_card, pendingOpenJob)

                // Intent 2: 1-Tap Quick Add Job
                val openAddIntent = Intent(context, NgelamarReminderWidgetProvider::class.java).apply {
                    action = ACTION_OPEN_NGELAMAR
                    putExtra("job_id", "")
                    putExtra("open_add_job", true)
                }
                val pendingOpenAdd = PendingIntent.getBroadcast(
                    context,
                    appWidgetId * 10 + 2,
                    openAddIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                safeSetOnClick(views, R.id.widget_btn_add, pendingOpenAdd)
                safeSetOnClick(views, R.id.widget_btn_empty_add, pendingOpenAdd)

                manager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to render widget $appWidgetId: ${e.message}", e)
            }
        }

        private fun safeSetText(views: RemoteViews, viewId: Int, text: CharSequence) {
            try {
                views.setTextViewText(viewId, text)
            } catch (_: Exception) {}
        }

        private fun safeSetVisibility(views: RemoteViews, viewId: Int, visibility: Int) {
            try {
                views.setViewVisibility(viewId, visibility)
            } catch (_: Exception) {}
        }

        private fun safeSetOnClick(views: RemoteViews, viewId: Int, pendingIntent: PendingIntent) {
            try {
                views.setOnClickPendingIntent(viewId, pendingIntent)
            } catch (_: Exception) {}
        }

        private fun launchApp(context: Context, jobId: String, openAddJob: Boolean = false) {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("from_home_widget", true)
                    putExtra("job_id", jobId)
                    putExtra("open_add_job", openAddJob)
                }
            if (launchIntent != null) context.startActivity(launchIntent)
        }
    }
}
