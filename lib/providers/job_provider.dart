import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/job_application.dart';
import '../services/prefs_service.dart';
import '../services/notification_service.dart';

class JobState {
  final List<JobApplication> jobs;
  final String searchQuery;
  final String selectedStatusFilter;
  final bool onlyFavoritesFilter;
  final bool onlyWfhFilter;
  final bool isLoading;
  final String userName;
  final String userEmail;
  final bool isDarkMode;

  JobState({
    required this.jobs,
    this.searchQuery = '',
    this.selectedStatusFilter = 'Semua',
    this.onlyFavoritesFilter = false,
    this.onlyWfhFilter = false,
    this.isLoading = false,
    this.userName = '',
    this.userEmail = '',
    this.isDarkMode = true,
  });

  JobState copyWith({
    List<JobApplication>? jobs,
    String? searchQuery,
    String? selectedStatusFilter,
    bool? onlyFavoritesFilter,
    bool? onlyWfhFilter,
    bool? isLoading,
    String? userName,
    String? userEmail,
    bool? isDarkMode,
  }) {
    return JobState(
      jobs: jobs ?? this.jobs,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      onlyFavoritesFilter: onlyFavoritesFilter ?? this.onlyFavoritesFilter,
      onlyWfhFilter: onlyWfhFilter ?? this.onlyWfhFilter,
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  // Metrics & Stats
  int get totalCount => jobs.length;
  int get appliedCount => jobs.where((j) => j.status == 'Dikirim').length;
  int get interviewCount => jobs
      .where(
        (j) =>
            j.status.contains('Interview') ||
            j.status == 'Tes / Psikotes',
      )
      .length;
  int get offeringCount => jobs.where((j) => j.status == 'Offering').length;
  int get acceptedCount => jobs.where((j) => j.status == 'Diterima').length;
  int get rejectedCount => jobs.where((j) => j.status == 'Ditolak').length;
  int get favoriteCount => jobs.where((j) => j.isFavorite).length;

  double get responseRate {
    if (jobs.isEmpty) return 0.0;
    final responded = jobs.where((j) => j.status != 'Dikirim').length;
    return (responded / jobs.length) * 100;
  }
}

class JobNotifier extends StateNotifier<JobState> {
  static const String _boxName = 'ngelamar_jobs_box';
  late final Future<Box<String>> _boxReady;

  JobNotifier() : super(JobState(jobs: [], isLoading: true)) {
    _boxReady = _initHiveAndLoad();
  }

  Future<Box<String>> _initHiveAndLoad() async {
    final box = await Hive.openBox<String>(_boxName);
    final List<JobApplication> loaded = [];

    for (var key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          loaded.add(JobApplication.fromJson(jsonStr));
        } catch (error) {
          // Data korup diabaikan agar data lain tetap dapat dibaca.
          debugPrint('Gagal membaca data lamaran dengan key $key: $error');
        }
      }
    }

    loaded.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

    // Muat preferensi pengguna
    final name = await PrefsService.getUserName() ?? '';
    final email = await PrefsService.getUserEmail() ?? '';
    final theme = await PrefsService.getThemeMode();

    state = state.copyWith(
      jobs: loaded,
      isLoading: false,
      userName: name,
      userEmail: email,
      isDarkMode: theme == 'dark',
    );

    // Sinkronisasi notifikasi dijalankan terpisah - kegagalan notifikasi
    // TIDAK boleh menggagalkan _boxReady sehingga seluruh CRUD tetap berfungsi.
    _syncNotificationsQuietly(loaded);

    return box;
  }

  /// Sinkronisasi pengingat notifikasi secara diam-diam (fire-and-forget).
  /// Kegagalan notifikasi tidak berdampak pada operasi penyimpanan data.
  void _syncNotificationsQuietly(Iterable<JobApplication> jobs) {
    NotificationService.syncAll(jobs).catchError((Object error) {
      debugPrint('Sinkronisasi notifikasi gagal (diabaikan): $error');
      return null;
    });
  }

  /// Jadwalkan pengingat notifikasi untuk satu lamaran secara diam-diam.
  void _scheduleReminderQuietly(JobApplication job) {
    NotificationService.syncInterviewReminder(job).catchError((Object error) {
      debugPrint('Penjadwalan notifikasi gagal (diabaikan): $error');
      return null;
    });
  }

  /// Batalkan pengingat notifikasi secara diam-diam.
  void _cancelReminderQuietly(String jobId) {
    NotificationService.cancelInterviewReminder(jobId).catchError(
      (Object error) {
        debugPrint('Pembatalan notifikasi gagal (diabaikan): $error');
        return null;
      },
    );
  }

  List<JobApplication> _normalizedJobs(Iterable<JobApplication> jobs) {
    final byId = <String, JobApplication>{};
    for (final job in jobs) {
      byId[job.id] = job;
    }
    final result = byId.values.toList();
    result.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));
    return result;
  }

  Future<void> loadSampleJobs() async {
    final box = await _boxReady;
    final samples = _generateSampleJobs();
    await box.putAll({
      for (final sample in samples) sample.id: sample.toJson(),
    });
    final updatedJobs = _normalizedJobs([...state.jobs, ...samples]);
    state = state.copyWith(jobs: updatedJobs);
    _syncNotificationsQuietly(updatedJobs);
  }

  Future<void> addJob(JobApplication job) async {
    final box = await _boxReady;
    await box.put(job.id, job.toJson());
    final newJobs = _normalizedJobs([...state.jobs, job]);
    state = state.copyWith(jobs: newJobs);
    // Notifikasi dijalankan setelah state berhasil diperbarui - kegagalan tidak
    // membatalkan penyimpanan data.
    _scheduleReminderQuietly(job);
  }

  Future<void> updateJob(JobApplication job) async {
    final box = await _boxReady;
    await box.put(job.id, job.toJson());
    final newJobs = _normalizedJobs([
      ...state.jobs.where((existing) => existing.id != job.id),
      job,
    ]);
    state = state.copyWith(jobs: newJobs);
    // Notifikasi diperbarui setelah state berhasil diperbarui.
    _scheduleReminderQuietly(job);
  }

  Future<void> toggleFavorite(String jobId) async {
    final index = state.jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      final updated = state.jobs[index].copyWith(
        isFavorite: !state.jobs[index].isFavorite,
      );
      await updateJob(updated);
    }
  }

  Future<void> updateStatus(String jobId, String newStatus) async {
    final jobIndex = state.jobs.indexWhere((j) => j.id == jobId);
    if (jobIndex != -1) {
      final updated = state.jobs[jobIndex].copyWith(status: newStatus);
      await updateJob(updated);
    }
  }

  Future<void> deleteJob(String jobId) async {
    final box = await _boxReady;
    await box.delete(jobId);
    final newJobs = state.jobs.where((j) => j.id != jobId).toList();
    state = state.copyWith(jobs: newJobs);
    _cancelReminderQuietly(jobId);
  }

  Future<void> importJobs(List<JobApplication> importedJobs) async {
    final box = await _boxReady;
    final normalized = _normalizedJobs([...state.jobs, ...importedJobs]);
    await box.putAll({for (final job in normalized) job.id: job.toJson()});
    state = state.copyWith(jobs: normalized);
    _syncNotificationsQuietly(normalized);
  }

  Future<void> clearAllJobs() async {
    final box = await _boxReady;
    await box.clear();
    state = state.copyWith(jobs: []);
    NotificationService.cancelAllInterviewReminders().catchError(
      (Object error) {
        debugPrint('Pembatalan semua notifikasi gagal (diabaikan): $error');
        return null;
      },
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(selectedStatusFilter: status);
  }

  void toggleOnlyFavoritesFilter() {
    state = state.copyWith(onlyFavoritesFilter: !state.onlyFavoritesFilter);
  }

  void toggleOnlyWfhFilter() {
    state = state.copyWith(onlyWfhFilter: !state.onlyWfhFilter);
  }

  void resetFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedStatusFilter: 'Semua',
      onlyFavoritesFilter: false,
      onlyWfhFilter: false,
    );
  }

  /// Save user name to prefs and update state.
  Future<void> setUserName(String name) async {
    await PrefsService.setUserName(name);
    state = state.copyWith(userName: name);
  }

  /// Save user email to prefs and update state.
  Future<void> setUserEmail(String email) async {
    await PrefsService.setUserEmail(email);
    state = state.copyWith(userEmail: email);
  }

  /// Toggle dark/light mode and persist to prefs.
  Future<void> toggleThemeMode() async {
    final isDark = !state.isDarkMode;
    await PrefsService.setThemeMode(isDark ? 'dark' : 'light');
    state = state.copyWith(isDarkMode: isDark);
  }

  List<JobApplication> _generateSampleJobs() {
    final now = DateTime.now();
    return [
      JobApplication(
        id: 'job_1',
        companyName: 'PT GoTo Indonesia',
        position: 'Junior Software Engineer',
        status: 'Interview HR',
        appliedDate: now.subtract(const Duration(days: 2)),
        salaryOffered: 'Rp 8.500.000 – Rp 12.000.000',
        workType: 'Hybrid',
        location: 'Jakarta Selatan',
        jobSource: 'LinkedIn',
        jobDescription:
            'Membutuhkan pengetahuan dasar Flutter, Dart, REST API, Git, dan pemahaman struktur data. Pengalaman 1-2 tahun di bidang mobile development menjadi nilai plus.',
        hrContact: '+6281234567890',
        interviewDate: now.add(const Duration(days: 2)),
        notes: 'Interview via Google Meet jam 10:00 WIB',
        isFavorite: true,
      ),
      JobApplication(
        id: 'job_2',
        companyName: 'BukaLapak',
        position: 'Frontend Developer Intern',
        status: 'Offering',
        appliedDate: now.subtract(const Duration(days: 6)),
        salaryOffered: 'Rp 6.000.000',
        workType: 'WFH',
        location: 'Jakarta',
        jobSource: 'Glints',
        jobDescription:
            'Mengembangkan fitur antarmuka web & mobile. Syarat: HTML/CSS, Flutter/React, Komunikasi baik.',
        hrContact: 'recruitment@bukalapak.com',
        notes: 'Penawaran offering berlaku sampai akhir minggu ini.',
        isFavorite: true,
      ),
      JobApplication(
        id: 'job_3',
        companyName: 'Bank Central Asia (BCA)',
        position: 'Management Trainee IT',
        status: 'Tes / Psikotes',
        appliedDate: now.subtract(const Duration(days: 4)),
        salaryOffered: 'Rp 9.000.000',
        workType: 'WFO',
        location: 'Tangerang / BSD',
        jobSource: 'Kalibrr',
        jobDescription:
            'Program MT IT BCA. Tes logika, algoritma dasar, dan Bahasa Inggris.',
        hrContact: '+6281987654321',
      ),
    ];
  }
}

final jobProvider = StateNotifierProvider<JobNotifier, JobState>((ref) {
  return JobNotifier();
});
