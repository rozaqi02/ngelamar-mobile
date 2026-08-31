package com.ngelamar.app.ngelamar

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.util.TimeZone

object DeviceCalendarBridge {
    private const val PREF = "ngelamar_device_calendar"
    private const val REQUEST_CALENDAR = 4721

    fun sync(activity: Activity, events: List<*>?) {
        if (!ensurePermission(activity)) return
        if (events == null) return
        val calendarId = primaryCalendarId(activity) ?: return
        val prefs = activity.getSharedPreferences(PREF, Context.MODE_PRIVATE)
        val editor = prefs.edit()

        for (raw in events) {
            val map = raw as? Map<*, *> ?: continue
            val key = map["key"]?.toString().orEmpty()
            if (key.isBlank()) continue
            val title = map["title"]?.toString().orEmpty()
            val description = map["description"]?.toString().orEmpty()
            val start = (map["startMillis"] as? Number)?.toLong() ?: continue
            val end = (map["endMillis"] as? Number)?.toLong() ?: (start + 60 * 60 * 1000)

            val existingId = prefs.getLong(key, -1L)
            val values = ContentValues().apply {
                put(CalendarContract.Events.CALENDAR_ID, calendarId)
                put(CalendarContract.Events.TITLE, title)
                put(CalendarContract.Events.DESCRIPTION, description)
                put(CalendarContract.Events.DTSTART, start)
                put(CalendarContract.Events.DTEND, end)
                put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
                put(CalendarContract.Events.CUSTOM_APP_PACKAGE, activity.packageName)
            }
            try {
                if (existingId > 0) {
                    val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, existingId)
                    activity.contentResolver.update(uri, values, null, null)
                } else {
                    val uri = activity.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
                    val id = uri?.lastPathSegment?.toLongOrNull()
                    if (id != null) editor.putLong(key, id)
                }
            } catch (_: SecurityException) {
                return
            } catch (_: Exception) {
                // Skip a single event; keep the rest of the batch.
            }
        }
        editor.apply()
    }

    fun openCalendar(context: Context) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = CalendarContract.CONTENT_URI
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            val fallback = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_APP_CALENDAR)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            try {
                context.startActivity(fallback)
            } catch (_: Exception) {
            }
        }
    }

    private fun ensurePermission(activity: Activity): Boolean {
        val write = ContextCompat.checkSelfPermission(activity, Manifest.permission.WRITE_CALENDAR)
        val read = ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_CALENDAR)
        if (write == PackageManager.PERMISSION_GRANTED && read == PackageManager.PERMISSION_GRANTED) {
            return true
        }
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR),
            REQUEST_CALENDAR,
        )
        return false
    }

    private fun primaryCalendarId(context: Context): Long? {
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.IS_PRIMARY,
        )
        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            null,
        )?.use { cursor ->
            val idIdx = cursor.getColumnIndex(CalendarContract.Calendars._ID)
            val primaryIdx = cursor.getColumnIndex(CalendarContract.Calendars.IS_PRIMARY)
            var fallback: Long? = null
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIdx)
                if (fallback == null) fallback = id
                if (primaryIdx >= 0 && cursor.getInt(primaryIdx) == 1) return id
            }
            return fallback
        }
        return null
    }
}
