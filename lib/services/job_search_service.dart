import '../models/job_application.dart';

/// Service terpusat untuk normalisasi dan algoritma pencarian lowongan kerja.
class JobSearchService {
  /// Membersihkan dan menormalisasi string: huruf kecil, hapus tanda baca, trim spasi berlebih.
  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Memecah kata kunci menjadi token pencarian setelah dinormalisasi
  static List<String> tokenize(String query) {
    return normalize(query)
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Mengecek apakah satu lowongan cocok dengan query pencarian multi-token
  static bool matchesJob(JobApplication job, String query) {
    final tokens = tokenize(query);
    if (tokens.isEmpty) return true;

    final searchable = [
      job.companyName,
      job.position,
      job.location ?? '',
      job.jobDescription,
      job.notes ?? '',
      job.hrContact ?? '',
      job.jobSource ?? '',
      job.sourcePlatform,
      job.workType,
      job.status,
      ...job.labels,
      ...job.skills,
    ].map((s) => normalize(s)).join(' ');

    return tokens.every((token) => searchable.contains(token));
  }

  /// Memfilter daftar lamaran berdasarkan query dan kriteria filter aktif
  static List<JobApplication> filterJobs(
    List<JobApplication> jobs, {
    String query = '',
    String status = 'Semua',
    String workType = 'Semua',
    bool onlyFavorites = false,
    bool onlyWfh = false,
  }) {
    return jobs.where((job) {
      if (query.trim().isNotEmpty && !matchesJob(job, query)) {
        return false;
      }
      if (status != 'Semua' && job.status != status) {
        return false;
      }
      if (workType != 'Semua' && job.workType != workType) {
        return false;
      }
      if (onlyFavorites && !job.isFavorite) {
        return false;
      }
      if (onlyWfh &&
          job.workType != 'WFH' &&
          !job.jobDescription.toLowerCase().contains('remote') &&
          !job.jobDescription.toLowerCase().contains('wfh')) {
        return false;
      }
      return true;
    }).toList();
  }
}
