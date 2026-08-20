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
    this.isDarkMode = false,
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

  /// Mengembalikan maksimal 4 lamaran prioritas untuk tumpukan kartu Beranda.
  /// Urutan prioritas: Offering / Interview / Tes ➔ Favorit ➔ Terbaru.
  List<JobApplication> get priorityJobs {
    if (jobs.isEmpty) return [];

    final list = List<JobApplication>.from(jobs);
    list.sort((a, b) {
      int score(JobApplication j) {
        if (j.status == 'Offering') return 10;
        if (j.status.contains('Interview')) return 8;
        if (j.status == 'Tes / Psikotes') return 6;
        if (j.isFavorite) return 4;
        if (j.status == 'Dikirim') return 2;
        return 0;
      }

      final scoreDiff = score(b).compareTo(score(a));
      if (scoreDiff != 0) return scoreDiff;
      return b.appliedDate.compareTo(a.appliedDate);
    });

    return list.take(4).toList();
  }
}

class JobNotifier extends StateNotifier<JobState> {
  static const String _boxName = 'ngelamar_jobs_box';
  late final Future<Box<String>> _boxReady;

  static const List<String> stageSequence = [
    'Dikirim',
    'Tes / Psikotes',
    'Interview HR',
    'Interview User',
    'Offering',
    'Diterima',
  ];

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
          debugPrint('Gagal membaca data lamaran dengan key $key: $error');
        }
      }
    }

    // Selalu pastikan data awal adalah data perusahaan Indonesia dengan format Rupiah
    final isInitialOrOutdated = loaded.isEmpty || loaded.any((j) => j.salaryOffered?.contains('\$') ?? false);
    if (isInitialOrOutdated) {
      await box.clear();
      loaded.clear();
      final samples = _generateSampleJobs();
      for (final sample in samples) {
        try {
          await box.put(sample.id, sample.toJson());
          loaded.add(sample);
        } catch (error) {
          debugPrint('Gagal menyimpan data sampel awal: $error');
        }
      }
    }

    loaded.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

    // Muat preferensi pengguna
    final name = await PrefsService.getUserName() ?? 'Rizki Pratama';
    final email = await PrefsService.getUserEmail() ?? 'rizki.pratama@email.com';
    final theme = await PrefsService.getThemeMode();

    state = state.copyWith(
      jobs: loaded,
      isLoading: false,
      userName: name,
      userEmail: email,
      isDarkMode: theme == 'dark',
    );

    _syncRemindersQuietly(loaded);
    return box;
  }

  void _syncRemindersQuietly(List<JobApplication> jobs) {
    NotificationService.syncAll(jobs).catchError((Object error) {
      debugPrint('Sinkronisasi notifikasi gagal: $error');
      return null;
    });
  }

  void _scheduleReminderQuietly(JobApplication job) {
    NotificationService.syncInterviewReminder(job).catchError((Object error) {
      debugPrint('Penjadwalan notifikasi gagal: $error');
      return null;
    });
  }

  void _cancelReminderQuietly(String jobId) {
    NotificationService.cancelInterviewReminder(jobId).catchError(
      (Object error) {
        debugPrint('Pembatalan notifikasi gagal: $error');
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
    await box.clear();
    final samples = _generateSampleJobs();
    await box.putAll({
      for (final sample in samples) sample.id: sample.toJson(),
    });
    state = state.copyWith(jobs: samples);
    _syncRemindersQuietly(samples);
  }

  Future<void> importJobs(List<JobApplication> newJobs) async {
    final box = await _boxReady;
    await box.putAll({
      for (final job in newJobs) job.id: job.toJson(),
    });
    final updated = _normalizedJobs([...state.jobs, ...newJobs]);
    state = state.copyWith(jobs: updated);
    _syncRemindersQuietly(updated);
  }

  Future<void> clearAllJobs() async {
    final box = await _boxReady;
    await box.clear();
    state = state.copyWith(jobs: []);
  }

  Future<void> addJob(JobApplication job) async {
    final box = await _boxReady;
    await box.put(job.id, job.toJson());
    final updated = _normalizedJobs([job, ...state.jobs]);
    state = state.copyWith(jobs: updated);
    _scheduleReminderQuietly(job);
  }

  /// 1-Tap Save dari Mesin Pencari Loker (Glints/JobStreet).
  Future<JobApplication> saveFromSearchEngine(JobApplication searchJob) async {
    final now = DateTime.now();
    final newJob = searchJob.copyWith(
      id: 'job_${now.millisecondsSinceEpoch}',
      status: 'Dikirim',
      appliedDate: now,
    );
    await addJob(newJob);
    return newJob;
  }

  /// Progres 1-Klik: Menaikkan tahapan seleksi ke langkah berikutnya.
  Future<String?> advanceToNextStage(String id) async {
    final job = state.jobs.firstWhere((j) => j.id == id);
    final currentIndex = stageSequence.indexOf(job.status);
    if (currentIndex != -1 && currentIndex < stageSequence.length - 1) {
      final nextStatus = stageSequence[currentIndex + 1];
      final updated = job.copyWith(status: nextStatus);
      await updateJob(updated);
      return nextStatus;
    }
    return null;
  }

  Future<void> updateJob(JobApplication job) async {
    final box = await _boxReady;
    await box.put(job.id, job.toJson());
    final updated = _normalizedJobs(
      state.jobs.map((j) => j.id == job.id ? job : j),
    );
    state = state.copyWith(jobs: updated);
    _scheduleReminderQuietly(job);
  }

  Future<void> deleteJob(String id) async {
    final box = await _boxReady;
    await box.delete(id);
    final updated = state.jobs.where((j) => j.id != id).toList();
    state = state.copyWith(jobs: updated);
    _cancelReminderQuietly(id);
  }

  Future<void> toggleFavorite(String id) async {
    final job = state.jobs.firstWhere((j) => j.id == id);
    final updated = job.copyWith(isFavorite: !job.isFavorite);
    await updateJob(updated);
  }

  Future<void> updateStatus(String id, String status) async {
    final job = state.jobs.firstWhere((j) => j.id == id);
    final updated = job.copyWith(status: status);
    await updateJob(updated);
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

  Future<void> setUserName(String name) async {
    await PrefsService.setUserName(name);
    state = state.copyWith(userName: name);
  }

  Future<void> setUserEmail(String email) async {
    await PrefsService.setUserEmail(email);
    state = state.copyWith(userEmail: email);
  }

  Future<void> toggleThemeMode() async {
    final isDark = !state.isDarkMode;
    await PrefsService.setThemeMode(isDark ? 'dark' : 'light');
    state = state.copyWith(isDarkMode: isDark);
  }

  List<JobApplication> _generateSampleJobs() {
    final now = DateTime.now();
    return [
      JobApplication(
        id: 'job_goto',
        companyName: 'PT GoTo Gojek Tokopedia Tbk',
        position: 'Senior Flutter Developer',
        status: 'Tes / Psikotes',
        appliedDate: now.subtract(const Duration(days: 1)),
        salaryOffered: 'Rp 22.000.000 / bln',
        minSalary: 22000000,
        maxSalary: 30000000,
        workType: 'Hybrid',
        location: 'Jakarta Selatan (Hybrid)',
        jobSource: 'Glints',
        sourcePlatform: 'Glints',
        jobUrl: 'https://glints.com/id/opportunities/jobs/senior-flutter-engineer',
        jobDescription:
            '• Menguasai pengembangan aplikasi mobile skala besar dengan Flutter & Dart.\n• Berpengalaman dengan Clean Architecture, State Management (Riverpod/Bloc), dan CI/CD.\n• Mampu berkolaborasi erat dengan Product Manager, UI/UX Designer, dan Backend Engineer.',
        hrContact: '+62 21 2910 1000',
        testDate: now.add(const Duration(days: 2)),
        isFavorite: true,
      ),
      JobApplication(
        id: 'job_bca',
        companyName: 'PT Bank Central Asia Tbk',
        position: 'Mobile Application Specialist',
        status: 'Interview HR',
        appliedDate: now.subtract(const Duration(days: 3)),
        salaryOffered: 'Rp 18.500.000 / bln',
        minSalary: 18500000,
        maxSalary: 24000000,
        workType: 'On-Site',
        location: 'Jakarta Barat (WFO)',
        jobSource: 'JobStreet',
        sourcePlatform: 'JobStreet',
        jobUrl: 'https://www.jobstreet.co.id/job/bca-mobile-developer',
        jobDescription:
            '• Pengalaman minimal 2 tahun dalam pengembangan mobile iOS/Android/Flutter.\n• Memahami secure coding standard untuk transaksi perbankan dan enkripsi data.\n• Berpengalaman dengan automated unit testing dan release store.',
        hrContact: 'recruitment@bca.co.id',
        interviewDate: now.add(const Duration(days: 3)),
        isFavorite: true,
      ),
      JobApplication(
        id: 'job_telkom',
        companyName: 'PT Telkom Indonesia Tbk',
        position: 'Lead Mobile Solution Architect',
        status: 'Interview User',
        appliedDate: now.subtract(const Duration(days: 5)),
        salaryOffered: 'Rp 26.000.000 / bln',
        minSalary: 26000000,
        maxSalary: 35000000,
        workType: 'Hybrid',
        location: 'Jakarta / Bandung',
        jobSource: 'JobStreet',
        sourcePlatform: 'JobStreet',
        jobUrl: 'https://www.jobstreet.co.id/job/telkom-lead-architect',
        jobDescription:
            '• Merancang arsitektur aplikasi mobile enterprise skala nasional.\n• Mendukung integrasi microservices, GraphQL, REST API, dan cloud infrastructure.\n• Memimpin tim developer dalam menerapkan best practice rekayasa perangkat lunak.',
        hrContact: 'careers@telkom.co.id',
        interviewDate: now.add(const Duration(days: 4)),
        isFavorite: false,
      ),
      JobApplication(
        id: 'job_shopee',
        companyName: 'PT Shopee International Indonesia',
        position: 'Software Development Engineer.',
        status: 'Offering',
        appliedDate: now.subtract(const Duration(days: 7)),
        salaryOffered: 'Rp 25.000.000 / bln',
        minSalary: 25000000,
        maxSalary: 32000000,
        workType: 'WFH',
        location: 'Jakarta Pusat (WFH)',
        jobSource: 'Glints',
        sourcePlatform: 'Glints',
        jobUrl: 'https://glints.com/id/opportunities/jobs/software-engineer-golang',
        jobDescription:
            '• Lulusan S1 Teknik Informatika, Sistem Informasi, atau pengalaman setara.\n• Memiliki portofolio aplikasi mobile nyata dengan performa tinggi dan clean code.\n• Menguasai algoritma pemecahan masalah, multi-threading, dan state management modern.',
        hrContact: 'hiring@shopee.co.id',
        notes: 'Sesi review offering package pada hari Jumat pukul 14:00 WIB.',
        isFavorite: true,
      ),
    ];
  }
}

final jobProvider = StateNotifierProvider<JobNotifier, JobState>((ref) {
  return JobNotifier();
});
