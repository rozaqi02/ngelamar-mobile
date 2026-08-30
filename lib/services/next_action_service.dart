import '../models/job_application.dart';

class NextActionSuggestion {
  final String type;
  final String note;
  final DateTime dueAt;

  const NextActionSuggestion({
    required this.type,
    required this.note,
    required this.dueAt,
  });
}

abstract final class NextActionService {
  static NextActionSuggestion? suggest(JobApplication job, {DateTime? now}) {
    if (job.isClosed || job.hasNextAction) return null;
    final base = now ?? DateTime.now();
    return switch (job.status) {
      'Dikirim' => NextActionSuggestion(
        type: 'Follow-up HR',
        note: 'Tanyakan perkembangan lamaran secara singkat dan sopan.',
        dueAt: base.add(const Duration(days: 5)),
      ),
      'Tes / Psikotes' => NextActionSuggestion(
        type: 'Persiapan tes',
        note: 'Periksa instruksi, perangkat, dan tenggat pengerjaan.',
        dueAt: base.add(const Duration(days: 1)),
      ),
      'Interview HR' || 'Interview User' => NextActionSuggestion(
        type: 'Latihan interview',
        note: 'Siapkan cerita pengalaman dan pertanyaan untuk pewawancara.',
        dueAt: base.add(const Duration(days: 1)),
      ),
      'Offering' => NextActionSuggestion(
        type: 'Evaluasi penawaran',
        note: 'Bandingkan gaji, benefit, lokasi, dan tanggal mulai.',
        dueAt: base.add(const Duration(days: 2)),
      ),
      _ => null,
    };
  }
}
