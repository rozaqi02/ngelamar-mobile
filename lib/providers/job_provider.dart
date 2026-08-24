import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/job_application.dart';
import '../services/prefs_service.dart';
import '../services/notification_service.dart';
import '../services/pro_verification_service.dart';
import '../services/secure_hive_service.dart';

class JobState {
  final List<JobApplication> jobs;
  final String searchQuery;
  final String selectedStatusFilter;
  final bool onlyFavoritesFilter;
  final bool onlyWfhFilter;
  final bool isLoading;
  final String userName;
  final String userEmail;
  final String userProfilePhoto;
  final bool isDarkMode;
  final bool isProUser;
  final DateTime? proExpiryDate;
  final String proPlanType;

  JobState({
    required this.jobs,
    this.searchQuery = '',
    this.selectedStatusFilter = 'Semua',
    this.onlyFavoritesFilter = false,
    this.onlyWfhFilter = false,
    this.isLoading = false,
    this.userName = '',
    this.userEmail = '',
    this.userProfilePhoto = '',
    this.isDarkMode = false,
    this.isProUser = false,
    this.proExpiryDate,
    this.proPlanType = 'monthly',
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
    String? userProfilePhoto,
    bool? isDarkMode,
    bool? isProUser,
    DateTime? proExpiryDate,
    bool clearProExpiryDate = false,
    String? proPlanType,
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
      userProfilePhoto: userProfilePhoto ?? this.userProfilePhoto,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isProUser: isProUser ?? this.isProUser,
      proExpiryDate: clearProExpiryDate
          ? null
          : (proExpiryDate ?? this.proExpiryDate),
      proPlanType: proPlanType ?? this.proPlanType,
    );
  }

  // Metrics & Stats
  int get totalCount => jobs.length;
  int get appliedCount => jobs.where((j) => j.status == 'Dikirim').length;
  int get interviewCount => jobs
      .where(
        (j) => j.status.contains('Interview') || j.status == 'Tes / Psikotes',
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

  /// Daftar lamaran yang telah disaring berdasarkan kata kunci dan filter aktif
  List<JobApplication> get filteredJobs {
    final queryTokens = searchQuery
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    return jobs.where((job) {
      if (queryTokens.isNotEmpty) {
        final pos = job.position.toLowerCase();
        final comp = job.companyName.toLowerCase();
        final loc = (job.location ?? '').toLowerCase();
        final desc = job.jobDescription.toLowerCase();
        final notes = (job.notes ?? '').toLowerCase();
        final hr = (job.hrContact ?? '').toLowerCase();

        // Setiap token pencarian harus cocok dengan minimal 1 atribut
        final allTokensMatch = queryTokens.every(
          (token) =>
              pos.contains(token) ||
              comp.contains(token) ||
              loc.contains(token) ||
              desc.contains(token) ||
              notes.contains(token) ||
              hr.contains(token),
        );

        if (!allTokensMatch) return false;
      }
      if (selectedStatusFilter != 'Semua' &&
          job.status != selectedStatusFilter) {
        return false;
      }
      if (onlyFavoritesFilter && !job.isFavorite) {
        return false;
      }
      if (onlyWfhFilter &&
          job.workType != 'WFH' &&
          !job.jobDescription.toLowerCase().contains('remote')) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Mengembalikan maksimal 4 lamaran prioritas untuk tumpukan kartu Beranda.
  /// Urutan prioritas: Offering / Interview / Tes -> Favorit -> Terbaru.
  List<JobApplication> get priorityJobs {
    final baseList =
        (selectedStatusFilter != 'Semua' ||
            onlyFavoritesFilter ||
            onlyWfhFilter ||
            searchQuery.isNotEmpty)
        ? filteredJobs
        : jobs;

    if (baseList.isEmpty) return [];

    final list = List<JobApplication>.from(baseList);
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

/// Thrown when a company and position already exist in the user's tracker.
class DuplicateJobException implements Exception {
  final JobApplication existingJob;

  const DuplicateJobException(this.existingJob);

  @override
  String toString() =>
      'Lamaran ${existingJob.position} di ${existingJob.companyName} sudah ada.';
}

class JobImportResult {
  final int importedCount;
  final int skippedCount;

  const JobImportResult({
    required this.importedCount,
    required this.skippedCount,
  });
}

class JobNotifier extends StateNotifier<JobState> {
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
    final box = await SecureHiveService.openJobsBox();
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

    final hasSeeded = await PrefsService.isInitialDataSeeded();

    // Ganti empat seed versi lama dengan paket enam data dummy yang konsisten.
    // ID ini hanya pernah dipakai oleh seed bawaan, bukan lamaran buatan user.
    const legacySampleIds = {'job_goto', 'job_bca', 'job_telkom', 'job_shopee'};
    if (loaded.any((job) => legacySampleIds.contains(job.id))) {
      loaded.removeWhere((job) => legacySampleIds.contains(job.id));
      final samples = _generateSampleJobs();
      loaded.addAll(samples);
      await box.deleteAll(legacySampleIds);
      await box.putAll({
        for (final sample in samples) sample.id: sample.toJson(),
      });
    }

    // Data contoh hanya boleh dimuat melalui pilihan eksplisit pada onboarding.
    // Versi lama tidak memiliki flag ini; jangan pernah menghapus data mereka.
    if (!hasSeeded && loaded.isNotEmpty) {
      await PrefsService.setInitialDataSeeded(true);
    }

    loaded.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

    // Muat preferensi pengguna
    final name = await PrefsService.getUserName() ?? '';
    final email = await PrefsService.getUserEmail() ?? '';
    final photo = await PrefsService.getProfilePhoto() ?? '';
    state = state.copyWith(
      jobs: loaded,
      isLoading: false,
      userName: name,
      userEmail: email,
      userProfilePhoto: photo,
      // Tema PRO tidak boleh diterapkan sebelum entitlement server terverifikasi.
      isDarkMode: false,
      isProUser: false,
      clearProExpiryDate: true,
      proPlanType: 'monthly',
    );

    unawaited(refreshProEntitlement());
    _syncRemindersQuietly(loaded);
    return box;
  }

  /// Refreshes PRO from Supabase. Local preferences are never trusted as an
  /// authorization source, so any failure leaves premium features locked.
  Future<void> refreshProEntitlement() async {
    final entitlement = await ProVerificationService.fetchCurrentEntitlement();
    final savedTheme = entitlement.isActive
        ? await PrefsService.getThemeMode()
        : 'light';
    state = state.copyWith(
      isProUser: entitlement.isActive,
      isDarkMode: entitlement.isActive && savedTheme == 'dark',
      proExpiryDate: entitlement.expiresAt,
      clearProExpiryDate: !entitlement.isActive,
      proPlanType: entitlement.plan,
    );
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
    NotificationService.cancelInterviewReminder(jobId).catchError((
      Object error,
    ) {
      debugPrint('Pembatalan notifikasi gagal: $error');
      return null;
    });
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

  JobApplication? _findDuplicate(
    JobApplication candidate, {
    String? excludingId,
  }) {
    final company = candidate.companyName.trim().toLowerCase();
    final position = candidate.position.trim().toLowerCase();
    return state.jobs.cast<JobApplication?>().firstWhere(
      (job) =>
          job != null &&
          job.id != excludingId &&
          job.companyName.trim().toLowerCase() == company &&
          job.position.trim().toLowerCase() == position,
      orElse: () => null,
    );
  }

  bool _isAttachmentStillReferenced(String path, {String? excludingId}) {
    return state.jobs.any(
      (job) =>
          job.id != excludingId &&
          (job.screenshotPath == path || job.companyLogoPath == path),
    );
  }

  Future<void> _deleteAttachmentIfUnused(
    String? path, {
    String? excludingId,
  }) async {
    if (kIsWeb || path == null || path.isEmpty) return;
    if (_isAttachmentStillReferenced(path, excludingId: excludingId)) return;

    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (error) {
      debugPrint('Gagal menghapus lampiran $path: $error');
    }
  }

  Future<void> _deleteAttachmentsForJobs(Iterable<JobApplication> jobs) async {
    for (final job in jobs) {
      await _deleteAttachmentIfUnused(job.screenshotPath, excludingId: job.id);
      await _deleteAttachmentIfUnused(job.companyLogoPath, excludingId: job.id);
    }
  }

  Future<bool> loadSampleJobs() async {
    try {
      final box = await _boxReady;
      final samples = _generateSampleJobs();
      await box.putAll({
        for (final sample in samples) sample.id: sample.toJson(),
      });
      final updated = _normalizedJobs([...state.jobs, ...samples]);
      state = state.copyWith(jobs: updated);
      _syncRemindersQuietly(updated);
      return true;
    } catch (e) {
      debugPrint('Error loading sample jobs: $e');
      return false;
    }
  }

  Future<JobImportResult> importJobs(List<JobApplication> newJobs) async {
    final box = await _boxReady;
    final accepted = <JobApplication>[];
    final seenCompanyPositions = <String>{
      for (final job in state.jobs) _duplicateKey(job),
    };
    final usedIds = <String>{for (final job in state.jobs) job.id};

    for (final job in newJobs) {
      final duplicateKey = _duplicateKey(job);
      if (seenCompanyPositions.contains(duplicateKey)) continue;

      var importedJob = job;
      if (usedIds.contains(job.id)) {
        importedJob = job.copyWith(
          id: 'job_import_${DateTime.now().microsecondsSinceEpoch}_${accepted.length}',
        );
      }
      accepted.add(importedJob);
      seenCompanyPositions.add(duplicateKey);
      usedIds.add(importedJob.id);
    }

    await box.putAll({for (final job in accepted) job.id: job.toJson()});
    final updated = _normalizedJobs([...state.jobs, ...accepted]);
    state = state.copyWith(jobs: updated);
    _syncRemindersQuietly(updated);
    return JobImportResult(
      importedCount: accepted.length,
      skippedCount: newJobs.length - accepted.length,
    );
  }

  String _duplicateKey(JobApplication job) =>
      '${job.companyName.trim().toLowerCase()}\u0000${job.position.trim().toLowerCase()}';

  Future<void> discardUnreferencedAttachments(Iterable<String> paths) async {
    for (final path in paths) {
      await _deleteAttachmentIfUnused(path);
    }
  }

  Future<bool> clearAllJobs() async {
    try {
      final box = await _boxReady;
      final jobsToDelete = List<JobApplication>.from(state.jobs);
      await box.clear();
      state = state.copyWith(jobs: []);
      await _deleteAttachmentsForJobs(jobsToDelete);
      await NotificationService.cancelAllInterviewReminders();
      return true;
    } catch (e) {
      debugPrint('Error clearing jobs: $e');
      return false;
    }
  }

  Future<void> addJob(JobApplication job) async {
    final duplicate = _findDuplicate(job);
    if (duplicate != null) throw DuplicateJobException(duplicate);

    final box = await _boxReady;
    await box.put(job.id, job.toJson());
    final updated = _normalizedJobs([job, ...state.jobs]);
    state = state.copyWith(jobs: updated);
    _scheduleReminderQuietly(job);
  }

  /// 1-Tap Save dari Mesin Pencari Loker (Glints/JobStreet) dengan proteksi anti-duplikasi.
  Future<JobApplication> saveFromSearchEngine(JobApplication searchJob) async {
    final duplicate = _findDuplicate(searchJob);
    if (duplicate != null) return duplicate;

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
    final existing = state.jobs.where((item) => item.id == job.id).firstOrNull;
    if (existing == null) {
      throw StateError('Lamaran yang ingin diperbarui tidak ditemukan.');
    }
    final duplicate = _findDuplicate(job, excludingId: job.id);
    if (duplicate != null) throw DuplicateJobException(duplicate);

    final box = await _boxReady;
    await box.put(job.id, job.toJson());
    final updated = _normalizedJobs(
      state.jobs.map((j) => j.id == job.id ? job : j),
    );
    state = state.copyWith(jobs: updated);

    if (existing.screenshotPath != job.screenshotPath) {
      await _deleteAttachmentIfUnused(existing.screenshotPath);
    }
    if (existing.companyLogoPath != job.companyLogoPath) {
      await _deleteAttachmentIfUnused(existing.companyLogoPath);
    }

    if (job.status == 'Ditolak' ||
        job.status == 'Diterima' ||
        (job.interviewDate == null && job.testDate == null)) {
      _cancelReminderQuietly(job.id);
    } else {
      _scheduleReminderQuietly(job);
    }
  }

  Future<void> deleteJob(String id) async {
    final job = state.jobs.where((item) => item.id == id).firstOrNull;
    if (job == null) return;
    final box = await _boxReady;
    await box.delete(id);
    final updated = state.jobs.where((j) => j.id != id).toList();
    state = state.copyWith(jobs: updated);
    await _deleteAttachmentsForJobs([job]);
    _cancelReminderQuietly(id);
  }

  Future<void> toggleFavorite(String id) async {
    final job = state.jobs.firstWhere((j) => j.id == id);
    final updated = job.copyWith(isFavorite: !job.isFavorite);
    await updateJob(updated);
  }

  Future<void> updateStatus(String id, String status) async {
    final job = state.jobs.firstWhere((j) => j.id == id);
    if (job.isSampleData) return;
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

  Future<void> setUserProfilePhoto(String sourcePath) async {
    var profilePhotoPath = sourcePath;
    if (!kIsWeb && sourcePath.isNotEmpty) {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw StateError('File foto profil tidak ditemukan.');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile');
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      final copied = await sourceFile.copy(
        '${profileDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      profilePhotoPath = copied.path;
    }

    final previousPath = state.userProfilePhoto;
    await PrefsService.setProfilePhoto(profilePhotoPath);
    state = state.copyWith(userProfilePhoto: profilePhotoPath);
    await _deleteManagedProfilePhoto(previousPath);
  }

  Future<void> _deleteManagedProfilePhoto(String path) async {
    if (kIsWeb || path.isEmpty) return;
    final appDir = await getApplicationDocumentsDirectory();
    final managedPrefix = '${appDir.path}/profile/';
    if (!path
        .replaceAll('\\', '/')
        .startsWith(managedPrefix.replaceAll('\\', '/'))) {
      return;
    }
    await _deleteAttachmentIfUnused(path);
  }

  Future<bool> toggleThemeMode() async {
    if (!state.isProUser) return false;
    final isDark = !state.isDarkMode;
    await PrefsService.setThemeMode(isDark ? 'dark' : 'light');
    state = state.copyWith(isDarkMode: isDark);
    return true;
  }

  List<JobApplication> _generateSampleJobs() {
    final now = DateTime.now();
    return [
      JobApplication(
        id: 'sample_nusa',
        companyName: 'Nusa Tech',
        position: 'Flutter Dev',
        status: 'Interview HR',
        appliedDate: now.subtract(const Duration(days: 1)),
        salaryOffered: 'Rp 8–11 jt / bln',
        minSalary: 8000000,
        maxSalary: 11000000,
        workType: 'Hybrid',
        location: 'Jakarta',
        jobSource: 'Portal A',
        sourcePlatform: 'Portal A',
        jobDescription:
            'Data dummy untuk mencoba tampilan detail lamaran dan fitur pelacakan.',
        isFavorite: true,
        isSampleData: true,
      ),
      JobApplication(
        id: 'sample_karsa',
        companyName: 'Karsa Labs',
        position: 'UI Designer',
        status: 'Offering',
        appliedDate: now.subtract(const Duration(days: 2)),
        salaryOffered: 'Rp 7–10 jt / bln',
        minSalary: 7000000,
        maxSalary: 10000000,
        workType: 'WFO',
        location: 'Bandung',
        jobSource: 'Portal B',
        sourcePlatform: 'Portal B',
        jobDescription:
            'Data dummy untuk melihat contoh lowongan desain di dalam tracker.',
        isFavorite: true,
        isSampleData: true,
      ),
      JobApplication(
        id: 'sample_bumi',
        companyName: 'Bumi Data',
        position: 'Data Analis',
        status: 'Tes / Psikotes',
        appliedDate: now.subtract(const Duration(days: 3)),
        salaryOffered: 'Rp 7–9 jt / bln',
        minSalary: 7000000,
        maxSalary: 9000000,
        workType: 'WFH',
        location: 'Remote',
        jobSource: 'Portal C',
        sourcePlatform: 'Portal C',
        jobDescription:
            'Data dummy untuk mencoba informasi gaji, lokasi, dan mode kerja.',
        isFavorite: false,
        isSampleData: true,
      ),
      JobApplication(
        id: 'sample_aruna',
        companyName: 'Aruna Mart',
        position: 'QA Engineer',
        status: 'Dikirim',
        appliedDate: now.subtract(const Duration(days: 4)),
        salaryOffered: 'Rp 6–9 jt / bln',
        minSalary: 6000000,
        maxSalary: 9000000,
        workType: 'Hybrid',
        location: 'Surabaya',
        jobSource: 'Portal D',
        sourcePlatform: 'Portal D',
        jobDescription:
            'Data dummy untuk mengeksplorasi catatan dan detail proses seleksi.',
        isFavorite: true,
        isSampleData: true,
      ),
      JobApplication(
        id: 'sample_sora',
        companyName: 'Sora Bank',
        position: 'HR Officer',
        status: 'Interview User',
        appliedDate: now.subtract(const Duration(days: 5)),
        salaryOffered: 'Rp 6–8 jt / bln',
        minSalary: 6000000,
        maxSalary: 8000000,
        workType: 'WFO',
        location: 'Bekasi',
        jobSource: 'Portal E',
        sourcePlatform: 'Portal E',
        jobDescription:
            'Data dummy untuk memahami susunan informasi pada kartu lamaran.',
        isFavorite: false,
        isSampleData: true,
      ),
      JobApplication(
        id: 'sample_tera',
        companyName: 'Tera Media',
        position: 'Copywriter',
        status: 'Dikirim',
        appliedDate: now.subtract(const Duration(days: 6)),
        salaryOffered: 'Rp 5–7 jt / bln',
        minSalary: 5000000,
        maxSalary: 7000000,
        workType: 'WFH',
        location: 'Bogor',
        jobSource: 'Portal F',
        sourcePlatform: 'Portal F',
        jobDescription:
            'Data dummy untuk mencoba pencarian, bookmark, serta mode grid dan list.',
        isFavorite: false,
        isSampleData: true,
      ),
    ];
  }

  /// Mengaktifkan status langganan PRO pengguna (Bulanan / Tahunan)
  Future<void> activateProSubscription({
    String plan = 'monthly',
    required DateTime verifiedExpiry,
  }) async {
    final now = DateTime.now();
    if (!verifiedExpiry.isAfter(now)) {
      throw ArgumentError.value(
        verifiedExpiry,
        'verifiedExpiry',
        'Masa aktif PRO harus berada di masa depan.',
      );
    }

    state = state.copyWith(
      isProUser: true,
      proExpiryDate: verifiedExpiry,
      proPlanType: plan,
    );
  }

  /// Membatalkan status langganan PRO
  Future<void> cancelProSubscription() async {
    await ProVerificationService.deactivateCurrentEntitlement();

    state = state.copyWith(
      isProUser: false,
      isDarkMode: false,
      clearProExpiryDate: true,
      proPlanType: 'monthly',
    );
  }
}

final jobProvider = StateNotifierProvider<JobNotifier, JobState>((ref) {
  return JobNotifier();
});
