import 'package:flutter/material.dart';

import 'job_application.dart';

enum CalendarEventType { application, selection, followUp, deadline }

@immutable
class CalendarEvent {
  final String id;
  final JobApplication job;
  final DateTime at;
  final String title;
  final CalendarEventType type;

  const CalendarEvent({
    required this.id,
    required this.job,
    required this.at,
    required this.title,
    required this.type,
  });

  DateTime get day => DateUtils.dateOnly(at);
  DateTime get date => at;
  String get companyName => job.companyName;
  String get position => job.position;
  String get companyHeroTag =>
      'calendar_company_logo_${job.id}_${at.microsecondsSinceEpoch}_${type.name}';
  String get legendKind => switch (type) {
    CalendarEventType.application => 'application',
    CalendarEventType.selection => 'interview',
    CalendarEventType.followUp => 'next_action',
    CalendarEventType.deadline => 'deadline',
  };
}

abstract final class CalendarEventAdapter {
  static List<CalendarEvent> fromJobs(Iterable<JobApplication> jobs) {
    final result = <CalendarEvent>[];
    final seen = <String>{};

    void add(
      JobApplication job,
      DateTime? at,
      String title,
      CalendarEventType type,
      String suffix,
    ) {
      if (at == null) return;
      final day = DateUtils.dateOnly(at).toIso8601String();
      final key = '${job.id}|$day|$suffix';
      if (!seen.add(key)) return;
      result.add(
        CalendarEvent(id: key, job: job, at: at, title: title, type: type),
      );
    }

    for (final job in jobs.where((job) => !job.isSampleData)) {
      if (job.isApplied) {
        add(
          job,
          job.appliedDate,
          'Lamaran dikirim',
          CalendarEventType.application,
          'application',
        );
      }
      add(
        job,
        job.interviewDate,
        job.status.startsWith('Interview') ? job.status : 'Wawancara',
        CalendarEventType.selection,
        'interview',
      );
      add(
        job,
        job.testDate,
        'Tes / Psikotes',
        CalendarEventType.selection,
        'test',
      );
      add(
        job,
        job.nextActionAt,
        job.nextActionType ?? 'Tindak lanjut',
        CalendarEventType.followUp,
        'next_action',
      );
      add(
        job,
        job.applicationDeadline,
        'Tenggat lamaran',
        CalendarEventType.deadline,
        'deadline',
      );
      for (final event in job.recruitmentEvents) {
        if (event.isDeleted || event.scheduledAt == null) continue;
        final type = switch (event.type.toLowerCase()) {
          final value
              when value.contains('deadline') || value.contains('tenggat') =>
            CalendarEventType.deadline,
          final value
              when value.contains('follow') || value.contains('tindak') =>
            CalendarEventType.followUp,
          _ => CalendarEventType.selection,
        };
        add(job, event.scheduledAt, event.title, type, 'event_${event.id}');
      }
    }
    result.sort((a, b) => a.at.compareTo(b.at));
    return List.unmodifiable(result);
  }

  static List<CalendarEventType> dotsForDay(
    Iterable<CalendarEvent> events,
    DateTime date, {
    int maxDots = 3,
  }) {
    final types = <CalendarEventType>[];
    for (final event in events) {
      if (!DateUtils.isSameDay(event.at, date) || types.contains(event.type)) {
        continue;
      }
      types.add(event.type);
      if (types.length == maxDots) break;
    }
    return types;
  }
}
