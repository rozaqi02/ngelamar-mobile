package com.ngelamar.app.ngelamar

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var launchChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launchChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ngelamar.app.ngelamar/home_widget",
        )
        launchChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "syncWidgetData" -> {
                    val payload = call.arguments as? Map<*, *>
                    if (payload == null) {
                        result.error("invalid_payload", "Data widget tidak valid.", null)
                        return@setMethodCallHandler
                    }
                    NgelamarWidgetStorage.save(applicationContext, payload)
                    NgelamarReminderWidgetProvider.updateAll(applicationContext)
                    NgelamarCalendarWidgetProvider.updateAll(applicationContext)
                    result.success(null)
                }
                "syncDeviceCalendar" -> {
                    val events = call.arguments as? List<*>
                    DeviceCalendarBridge.sync(this, events)
                    result.success(null)
                }
                "openDeviceCalendar" -> {
                    DeviceCalendarBridge.openCalendar(this)
                    result.success(null)
                }
                "getInitialLaunchData" -> {
                    val launchIntent = intent
                    val fromWidget = launchIntent?.getBooleanExtra("from_home_widget", false) ?: false
                    val jobId = launchIntent?.getStringExtra("job_id") ?: ""
                    val openAddJob = launchIntent?.getBooleanExtra("open_add_job", false) ?: false
                    val openCalendar = launchIntent?.getBooleanExtra("open_calendar", false) ?: false
                    if (fromWidget) {
                        // Consumed: avoid replaying the widget action on the next resume.
                        launchIntent?.removeExtra("from_home_widget")
                        launchIntent?.removeExtra("job_id")
                        launchIntent?.removeExtra("open_add_job")
                        launchIntent?.removeExtra("open_calendar")
                    }
                    val isShare = launchIntent?.action == Intent.ACTION_SEND &&
                        launchIntent.type?.startsWith("text/") == true
                    val sharedText = if (isShare) {
                        listOfNotNull(
                            launchIntent.getStringExtra(Intent.EXTRA_SUBJECT),
                            launchIntent.getStringExtra(Intent.EXTRA_TEXT),
                        ).joinToString("\n").trim()
                    } else ""
                    result.success(mapOf(
                        "from_home_widget" to fromWidget,
                        "job_id" to jobId,
                        "open_add_job" to openAddJob,
                        "open_calendar" to openCalendar,
                        "from_share" to (isShare && sharedText.isNotBlank()),
                        "shared_text" to sharedText,
                    ))
                    if (isShare) {
                        launchIntent?.removeExtra(Intent.EXTRA_SUBJECT)
                        launchIntent?.removeExtra(Intent.EXTRA_TEXT)
                        launchIntent?.action = null
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(newIntent: Intent) {
        super.onNewIntent(newIntent)
        setIntent(newIntent)
        val isShare = newIntent.action == Intent.ACTION_SEND &&
            newIntent.type?.startsWith("text/") == true
        if (isShare) {
            val sharedText = listOfNotNull(
                newIntent.getStringExtra(Intent.EXTRA_SUBJECT),
                newIntent.getStringExtra(Intent.EXTRA_TEXT),
            ).joinToString("\n").trim()
            if (sharedText.isNotBlank()) {
                launchChannel?.invokeMethod(
                    "launchDataChanged",
                    mapOf("from_share" to true, "shared_text" to sharedText),
                )
            }
            newIntent.removeExtra(Intent.EXTRA_SUBJECT)
            newIntent.removeExtra(Intent.EXTRA_TEXT)
            newIntent.action = null
            return
        }
        // Home-screen widget taps arrive here while the activity is warm.
        if (newIntent.getBooleanExtra("from_home_widget", false)) {
            launchChannel?.invokeMethod(
                "launchDataChanged",
                mapOf(
                    "from_home_widget" to true,
                    "job_id" to (newIntent.getStringExtra("job_id") ?: ""),
                    "open_add_job" to newIntent.getBooleanExtra("open_add_job", false),
                    "open_calendar" to newIntent.getBooleanExtra("open_calendar", false),
                ),
            )
            newIntent.removeExtra("from_home_widget")
            newIntent.removeExtra("job_id")
            newIntent.removeExtra("open_add_job")
            newIntent.removeExtra("open_calendar")
        }
    }
}
