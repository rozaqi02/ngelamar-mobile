import '../providers/job_provider.dart';

enum ReminderCommandType { complete, snoozeTomorrow }

class ReminderCommand {
  final ReminderCommandType type;
  final String jobId;

  const ReminderCommand({required this.type, required this.jobId});

  String get idempotencyKey => '${type.name}:$jobId';
}

/// Executes commands from notifications, widgets, and in-app agenda through
/// the same provider API, keeping their behavior deterministic.
abstract final class ReminderCommandService {
  static final Set<String> _inFlight = <String>{};

  static Future<bool> execute(
    JobNotifier notifier,
    ReminderCommand command, {
    DateTime? now,
  }) async {
    if (!_inFlight.add(command.idempotencyKey)) return false;
    try {
      switch (command.type) {
        case ReminderCommandType.complete:
          await notifier.completeNextAction(command.jobId);
          break;
        case ReminderCommandType.snoozeTomorrow:
          final base = now ?? DateTime.now();
          await notifier.snoozeFollowUp(
            command.jobId,
            customDate: DateTime(base.year, base.month, base.day + 1, 9),
          );
          break;
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _inFlight.remove(command.idempotencyKey);
    }
  }
}
