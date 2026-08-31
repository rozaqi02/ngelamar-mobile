import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/calendar_event.dart';
import '../models/job_application.dart';

/// Writes upcoming Ngelamar agenda into the device calendar, and can open
/// the system calendar app. Android-only; no-ops on other platforms.
class DeviceCalendarService {
  static const MethodChannel _channel = MethodChannel(
    'com.ngelamar.app.ngelamar/home_widget',
  );

  static Future<void> syncJobs(Iterable<JobApplication> jobs) async {
    if (kIsWeb || !Platform.isAndroid) return;
    final events = CalendarEventAdapter.fromJobs(jobs)
        .where(
          (event) => !event.at.isBefore(
            DateTime.now().subtract(const Duration(hours: 2)),
          ),
        )
        .take(40)
        .map(
          (event) => {
            'key': event.id,
            'title': '${event.title} · ${event.job.companyName}',
            'description': '${event.job.position} — dicatat via Ngelamar',
            'startMillis': event.at.millisecondsSinceEpoch,
            'endMillis': event.at
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch,
          },
        )
        .toList(growable: false);
    try {
      await _channel.invokeMethod<void>('syncDeviceCalendar', events);
    } catch (error) {
      debugPrint('Sinkronisasi kalender perangkat gagal: $error');
    }
  }

  static Future<void> openSystemCalendar() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openDeviceCalendar');
    } catch (error) {
      debugPrint('Tidak dapat membuka kalender perangkat: $error');
    }
  }
}
