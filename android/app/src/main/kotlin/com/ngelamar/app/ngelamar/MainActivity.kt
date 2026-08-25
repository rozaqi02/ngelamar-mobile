package com.ngelamar.app.ngelamar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ngelamar.app.ngelamar/home_widget",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncWidgetData" -> {
                    val payload = call.arguments as? Map<*, *>
                    if (payload == null) {
                        result.error("invalid_payload", "Data widget tidak valid.", null)
                        return@setMethodCallHandler
                    }
                    NgelamarWidgetStorage.save(applicationContext, payload)
                    NgelamarReminderWidgetProvider.updateAll(applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
