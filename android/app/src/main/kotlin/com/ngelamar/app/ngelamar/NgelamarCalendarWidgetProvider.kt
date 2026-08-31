package com.ngelamar.app.ngelamar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

class NgelamarCalendarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { render(context, appWidgetManager, it) }
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val provider = ComponentName(context, NgelamarCalendarWidgetProvider::class.java)
            manager.getAppWidgetIds(provider).forEach { render(context, manager, it) }
        }

        private fun render(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
            val data = NgelamarWidgetStorage.read(context)
            val views = RemoteViews(context.packageName, R.layout.ngelamar_calendar_widget)
            views.setTextViewText(R.id.cal_month, data.monthLabel.ifBlank { "KALENDER" })
            views.setTextViewText(R.id.cal_count, "${data.agendaCount} agenda")

            val e1Title = data.event1Title.ifBlank { "Belum ada agenda" }
            val e1When = data.event1When.ifBlank { "Santai dulu" }
            views.setTextViewText(R.id.cal_e1_title, e1Title)
            views.setTextViewText(R.id.cal_e1_when, e1When)
            views.setTextViewText(R.id.cal_e2_title, data.event2Title)
            views.setTextViewText(R.id.cal_e2_when, data.event2When)
            views.setTextViewText(R.id.cal_e3_title, data.event3Title)
            views.setTextViewText(R.id.cal_e3_when, data.event3When)
            views.setViewVisibility(
                R.id.cal_e2_title,
                if (data.event2Title.isBlank()) View.GONE else View.VISIBLE,
            )
            views.setViewVisibility(
                R.id.cal_e2_when,
                if (data.event2When.isBlank()) View.GONE else View.VISIBLE,
            )
            views.setViewVisibility(
                R.id.cal_e3_title,
                if (data.event3Title.isBlank()) View.GONE else View.VISIBLE,
            )
            views.setViewVisibility(
                R.id.cal_e3_when,
                if (data.event3When.isBlank()) View.GONE else View.VISIBLE,
            )

            val open = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("from_home_widget", true)
                putExtra("open_calendar", true)
            }
            val pending = PendingIntent.getActivity(
                context,
                appWidgetId + 9000,
                open,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.cal_root, pending)
            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
