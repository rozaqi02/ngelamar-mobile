import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/job_application.dart';
import '../repositories/profile_repository.dart';
import '../services/job_search_service.dart';
import '../services/prefs_service.dart';
import '../services/notification_service.dart';
import '../services/android_home_widget_service.dart';
import '../services/device_calendar_service.dart';
import '../services/pro_verification_service.dart';
import '../services/secure_hive_service.dart';

class JobState {
  final List<JobApplication> jobs;
  final String searchQuery;
  final String selectedStatusFilter;
  final String selectedWorkTypeFilter;
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
    this.selectedWorkTypeFilter = 'Semua',
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
    String? selectedWorkTypeFilter,
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
      selectedWorkTypeFilter:
          selectedWorkTypeFilter ?? this.selectedWorkTypeFilter,
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

  // Metrics & Stats (excludes sample tutorial data to ensure clean, accurate metrics)
  List<JobApplication> get realJobs =>
      jobs.where((j) => !j.isSampleData).toList();

  int get totalCount => realJobs.length;
  int get savedCount => realJobs.where((j) => j.isSaved).length;
  int get draftCount => realJobs.where((j) => j.isDraft).length;
  int get appliedCount => realJobs.where((j) => j.isApplied).length;
  int get sentOnlyCount => realJobs.where((j) => j.status == 'Dikirim').length;
  int get ghostedCount => realJobs.where((j) => j.isGhosted).length;
  int get interviewCount => realJobs
      .where(
        (j) =>
            (j.status.contains('Interview') || j.status == 'Tes / Psikotes') &&
            j.isApplied,
      )
      .length;
  int get offeringCount => realJobs.where((j) => j.status == 'Offering').length;
  int get acceptedCount => realJobs.where((j) => j.status == 'Diterima').length;
  int get rejectedCount => realJobs.where((j) => j.status == 'Ditolak').length;
  int get favoriteCount => realJobs.where((j) => j.isFavorite).length;
  bool get hasSampleData => jobs.any((j) => j.isSampleData);

  double get responseRate {
    final activeApplied = realJobs.where((j) => j.isApplied).toList();
    if (activeApplied.isEmpty) return 0.0;
    final responded = activeApplied.where((j) => j.status != 'Dikirim').length;
    return (responded / activeApplied.length) * 100;
  }

  /// Daftar lamaran yang telah disaring berdasarkan kata kunci dan filter aktif
  List<JobApplication> get filteredJobs => JobSearchService.filterJobs(
    jobs,
    query: searchQuery,
    status: selectedStatusFilter,
    workType: selectedWorkTypeFilter,
    onlyFavorites: onlyFavoritesFilter,
    onlyWfh: onlyWfhFilter,
  );

  /// Mengembalikan maksimal 4 lamaran prioritas untuk tumpukan kartu Beranda.
  /// Urutan prioritas: Offering / Interview / Tes -> Favorit -> Dikirim -> Tersimpan.
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
        if (j.status == 'Tersimpan') return 1;
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
    'Tersimpan',
    'Draft',
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
    unawaited(ProfileRepository().initialize());
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
    _syncWidgetQuietly(loaded);
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

  void _syncWidgetQuietly(List<JobApplication> jobs) {
    AndroidHomeWidgetService.syncJobs(jobs).catchError((Object error) {
      debugPrint('Sinkronisasi widget Android gagal: $error');
    });
    DeviceCalendarService.syncJobs(jobs).catchError((Object error) {
      debugPrint('Sinkronisasi kalender perangkat gagal: $error');
    });
  }

  void _scheduleReminderQuietly(JobApplication job) {
    NotificationService.syncJobReminders(job).catchError((Object error) {
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

  JobApplication? findDuplicate({
    required String companyName,
    required String position,
    bool allowReapplyAfterPeriod = false,
  }) {
    return _findDuplicate(
      JobApplication(
        id: '_probe',
        companyName: companyName,
        position: position,
        status: 'Tersimpan',
        appliedDate: DateTime.now(),
        workType: 'Belum ditentukan',
        jobDescription: '',
      ),
      allowReapplyAfterPeriod: allowReapplyAfterPeriod,
    );
  }

  JobApplication? _findDuplicate(
    JobApplication candidate, {
    String? excludingId,
    bool allowReapplyAfterPeriod = true,
  }) {
    final company = _normalizeName(candidate.companyName);
    final position = _normalizeName(candidate.position);
    if (company.isEmpty || position.isEmpty) return null;

    return state.jobs.cast<JobApplication?>().firstWhere((job) {
      if (job == null || job.id == excludingId) return false;
      final existingCompany = _normalizeName(job.companyName);
      final existingPosition = _normalizeName(job.position);
      if (existingCompany != company || existingPosition != position) {
        return false;
      }
      if (allowReapplyAfterPeriod) {
        // If previous application was > 90 days ago or is already closed (Ditolak / Diterima),
        // allow creating a new re-application record
        final daysDiff = candidate.appliedDate
            .difference(job.appliedDate)
            .inDays
            .abs();
        if (daysDiff >= 90 ||
            job.status == 'Ditolak' ||
            job.status == 'Diterima') {
          return false;
        }
      }
      return true;
    }, orElse: () => null);
  }

  static String _normalizeName(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isAttachmentStillReferenced(String path, {String? excludingId}) {
    return state.jobs.any(
      (job) =>
          job.id != excludingId &&
          (job.screenshotPath == path ||
              job.companyLogoPath == path ||
              job.pdfCvPath == path ||
              job.attachments.any((attachment) => attachment.path == path)),
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
      await _deleteAttachmentIfUnused(job.pdfCvPath, excludingId: job.id);
      for (final attachment in job.attachments) {
        await _deleteAttachmentIfUnused(attachment.path, excludingId: job.id);
      }
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
      _syncWidgetQuietly(updated);
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
    _syncWidgetQuietly(updated);
    return JobImportResult(
      importedCount: accepted.length,
      skippedCount: newJobs.length - accepted.length,
    );
  }

  String _duplicateKey(JobApplication job) =>
      '${_normalizeName(job.companyName)}\u0000${_normalizeName(job.position)}';

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
      _syncWidgetQuietly(const []);
      return true;
    } catch (e) {
      debugPrint('Error clearing jobs: $e');
      return false;
    }
  }

  Future<void> addJob(JobApplication job, {bool allowDuplicate = false}) async {
    if (!allowDuplicate) {
      final duplicate = _findDuplicate(job);
      if (duplicate != null) throw DuplicateJobException(duplicate);
    }

    final savedJob = _ensureInitialHistory(job);
    final box = await _boxReady;
    await box.put(savedJob.id, savedJob.toJson());
    final updated = _normalizedJobs([savedJob, ...state.jobs]);
    state = state.copyWith(jobs: updated);
    _scheduleReminderQuietly(savedJob);
    _syncWidgetQuietly(updated);
  }

  /// 1-Tap Save dari Mesin Pencari Loker (Glints/JobStreet) dengan status default 'Tersimpan'.
  Future<JobApplication> saveFromSearchEngine(JobApplication searchJob) async {
    final duplicate = _findDuplicate(searchJob);
    if (duplicate != null) return duplicate;

    final now = DateTime.now();
    final newJob = searchJob.copyWith(
      id: 'job_${now.millisecondsSinceEpoch}',
      status: 'Tersimpan',
      savedAt: now,
      appliedDate: now,
    );
    await addJob(newJob);
    return newJob;
  }

  /// Menghapus seluruh data contoh tutorial secara aman dengan 1 klik.
  Future<int> deleteSampleJobs() async {
    final box = await _boxReady;
    final samples = state.jobs.where((j) => j.isSampleData).toList();
    if (samples.isEmpty) return 0;

    await box.deleteAll(samples.map((j) => j.id));
    final updated = state.jobs.where((j) => !j.isSampleData).toList();
    state = state.copyWith(jobs: updated);
    _syncRemindersQuietly(updated);
    _syncWidgetQuietly(updated);
    return samples.length;
  }

  /// Menyimpan lowongan belum lengkap sebagai 'Draft'.
  Future<JobApplication> saveAsDraft(JobApplication draftJob) async {
    final duplicate = _findDuplicate(draftJob);
    if (duplicate != null) return duplicate;

    final now = DateTime.now();
    final newJob = draftJob.copyWith(
      id: draftJob.id.isEmpty
          ? 'job_${now.millisecondsSinceEpoch}'
          : draftJob.id,
      status: 'Draft',
      savedAt: now,
      appliedDate: now,
    );
    await addJob(newJob);
    return newJob;
  }

  /// Progres 1-Klik: Menaikkan tahapan seleksi ke langkah berikutnya.
  Future<String?> advanceToNextStage(String id) async {
    final job = state.jobs.firstWhere((j) => j.id == id);
    var currentIndex = stageSequence.indexOf(job.status);
    if (currentIndex == -1) {
      if (job.status == 'Tersimpan' || job.status == 'Draft') {
        currentIndex = 0;
      }
    }
    if (currentIndex != -1 && currentIndex < stageSequence.length - 1) {
      final nextStatus = stageSequence[currentIndex + 1];
      final isNowSent =
          (job.status == 'Tersimpan' || job.status == 'Draft') &&
          nextStatus == 'Dikirim';
      final updated = job.copyWith(
        status: nextStatus,
        appliedDate: isNowSent ? DateTime.now() : job.appliedDate,
        closedAt: (nextStatus == 'Diterima' || nextStatus == 'Ditolak')
            ? DateTime.now()
            : null,
      );
      await updateJob(updated);
      return nextStatus;
    }
    return null;
  }

  Future<void> updateJob(
    JobApplication job, {
    bool allowDuplicate = false,
  }) async {
    final existing = state.jobs.where((item) => item.id == job.id).firstOrNull;
    if (existing == null) {
      throw StateError('Lamaran yang ingin diperbarui tidak ditemukan.');
    }
    if (!allowDuplicate) {
      final duplicate = _findDuplicate(job, excludingId: job.id);
      if (duplicate != null) throw DuplicateJobException(duplicate);
    }

    final savedJob = _withStatusHistory(existing, job);
    final box = await _boxReady;
    await box.put(savedJob.id, savedJob.toJson());
    final updated = _normalizedJobs(
      state.jobs.map((j) => j.id == savedJob.id ? savedJob : j),
    );
    state = state.copyWith(jobs: updated);
    _syncWidgetQuietly(updated);

    if (existing.screenshotPath != savedJob.screenshotPath) {
      await _deleteAttachmentIfUnused(existing.screenshotPath);
    }
    if (existing.companyLogoPath != savedJob.companyLogoPath) {
      await _deleteAttachmentIfUnused(existing.companyLogoPath);
    }
    if (existing.pdfCvPath != savedJob.pdfCvPath) {
      await _deleteAttachmentIfUnused(existing.pdfCvPath);
    }
    for (final attachment in existing.attachments) {
      if (!savedJob.attachments.any((item) => item.path == attachment.path)) {
        await _deleteAttachmentIfUnused(attachment.path);
      }
    }

    if (savedJob.status == 'Ditolak' ||
        savedJob.status == 'Diterima' ||
        (savedJob.interviewDate == null && savedJob.testDate == null)) {
      _cancelReminderQuietly(savedJob.id);
    } else {
      _scheduleReminderQuietly(savedJob);
    }
  }

  JobApplication _ensureInitialHistory(JobApplication job) {
    if (job.recruitmentEvents.isNotEmpty) return job;
    return job.copyWith(
      recruitmentEvents: [
        RecruitmentEvent(
          id: 'event_applied_${job.id}',
          type: 'lamaran_dikirim',
          title: job.status == 'Dikirim'
              ? 'Lamaran dikirim'
              : 'Lamaran dicatat (${job.status})',
          occurredAt: job.appliedDate,
        ),
      ],
      updatedAt: DateTime.now(),
    );
  }

  JobApplication _withStatusHistory(
    JobApplication existing,
    JobApplication candidate,
  ) {
    final now = DateTime.now();
    final existingEvents = existing.recruitmentEvents.isEmpty
        ? _ensureInitialHistory(existing).recruitmentEvents
        : existing.recruitmentEvents;
    final statusChanged = existing.status != candidate.status;
    return candidate.copyWith(
      createdAt: existing.createdAt,
      updatedAt: now,
      recruitmentEvents: statusChanged
          ? [
              ...existingEvents,
              RecruitmentEvent(
                id: 'event_status_${candidate.id}_${now.microsecondsSinceEpoch}',
                type: 'status',
                title: 'Status menjadi ${candidate.status}',
                occurredAt: now,
                notes: candidate.outcomeReason,
              ),
            ]
          : (candidate.recruitmentEvents.isEmpty
                ? existingEvents
                : candidate.recruitmentEvents),
    );
  }

  Future<void> setNextAction({
    required String jobId,
    required DateTime? dueAt,
    String? type,
    String? note,
  }) async {
    final job = state.jobs.firstWhere((item) => item.id == jobId);
    await updateJob(
      job.copyWith(
        nextActionAt: dueAt,
        nextActionType: type,
        nextActionNote: note,
        clearNextAction: dueAt == null,
      ),
    );
  }

  Future<void> deleteJob(
    String id, {
    bool deleteFilesImmediately = false,
  }) async {
    final job = state.jobs.where((item) => item.id == id).firstOrNull;
    if (job == null) return;
    final box = await _boxReady;
    await box.delete(id);
    final updated = state.jobs.where((j) => j.id != id).toList();
    state = state.copyWith(jobs: updated);
    if (deleteFilesImmediately) {
      await _deleteAttachmentsForJobs([job]);
    }
    _cancelReminderQuietly(id);
    _syncWidgetQuietly(updated);
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

  Future<void> convertSampleJobToReal(String id) async {
    final job = state.jobs.firstWhere((j) => j.id == id);
    final updated = job.copyWith(isSampleData: false);
    await updateJob(updated);
  }

  /// Menambahkan event kronologis rekrutmen baru
  Future<void> addRecruitmentEvent(String jobId, RecruitmentEvent event) async {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    final updatedEvents = [...job.recruitmentEvents, event];
    final updated = job.copyWith(
      recruitmentEvents: updatedEvents,
      updatedAt: DateTime.now(),
    );
    await updateJob(updated);
  }

  /// Menunda (snooze) pengingat follow-up
  Future<void> snoozeFollowUp(
    String jobId, {
    Duration duration = const Duration(days: 3),
    DateTime? customDate,
  }) async {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    final targetDate = customDate ?? DateTime.now().add(duration);
    final event = RecruitmentEvent(
      id: 'evt_snooze_${DateTime.now().millisecondsSinceEpoch}',
      type: 'followup_snooze',
      title: 'Follow-up Ditunda',
      occurredAt: DateTime.now(),
      scheduledAt: targetDate,
      notes:
          'Pengingat follow-up ditunda hingga ${_formatDateSimple(targetDate)}',
    );
    final updated = job.copyWith(
      nextActionAt: targetDate,
      nextActionType: 'Follow-up HR',
      nextActionNote: 'Tindak lanjut HR (Snoozed)',
      recruitmentEvents: [...job.recruitmentEvents, event],
      updatedAt: DateTime.now(),
    );
    await updateJob(updated);
  }

  /// Menandai follow-up sudah dilakukan atau diabaikan
  Future<void> dismissFollowUp(
    String jobId, {
    bool noFollowUpNeeded = false,
  }) async {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    final now = DateTime.now();
    final event = RecruitmentEvent(
      id: 'evt_followup_${now.millisecondsSinceEpoch}',
      type: noFollowUpNeeded ? 'followup_dismissed' : 'followup_done',
      title: noFollowUpNeeded ? 'Follow-up Diabaikan' : 'Follow-up Terkirim',
      occurredAt: now,
      notes: noFollowUpNeeded
          ? 'Pengguna memilih tidak perlu follow-up untuk lowongan ini.'
          : 'Pengguna telah menghubungi recruiter / HR untuk follow-up.',
    );
    final updated = job.copyWith(
      lastFollowUpAt: now,
      followUpCount: job.followUpCount + 1,
      clearNextAction: true,
      recruitmentEvents: [...job.recruitmentEvents, event],
      updatedAt: now,
    );
    await updateJob(updated);
  }

  /// Menyelesaikan tindakan lanjutan (Next Action)
  Future<void> completeNextAction(String jobId, {String? outcome}) async {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    final now = DateTime.now();
    final event = RecruitmentEvent(
      id: 'evt_action_done_${now.millisecondsSinceEpoch}',
      type: 'action_completed',
      title: job.nextActionType ?? 'Tindakan Selesai',
      occurredAt: now,
      completedAt: now,
      notes: job.nextActionNote,
      outcome: outcome,
    );
    final updated = job.copyWith(
      clearNextAction: true,
      recruitmentEvents: [...job.recruitmentEvents, event],
      updatedAt: now,
    );
    await updateJob(updated);
  }

  /// Menjadwalkan ulang (reschedule) tanpa menghapus histori sebelumnya
  Future<void> rescheduleStage(
    String jobId,
    DateTime newDate, {
    String? reason,
  }) async {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    final now = DateTime.now();
    final event = RecruitmentEvent(
      id: 'evt_resched_${now.millisecondsSinceEpoch}',
      type: 'reschedule',
      title: 'Jadwal Diubah (${job.status})',
      occurredAt: now,
      scheduledAt: newDate,
      notes: reason ?? 'Jadwal interview/tes disesuaikan ke tanggal baru.',
    );
    final updated = job.copyWith(
      interviewDate: job.status.startsWith('Interview')
          ? newDate
          : job.interviewDate,
      testDate: job.status == 'Tes / Psikotes' ? newDate : job.testDate,
      recruitmentEvents: [...job.recruitmentEvents, event],
      updatedAt: now,
    );
    await updateJob(updated);
  }

  static String _formatDateSimple(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(selectedStatusFilter: status);
  }

  void setWorkTypeFilter(String workType) {
    state = state.copyWith(selectedWorkTypeFilter: workType);
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
      selectedWorkTypeFilter: 'Semua',
      onlyFavoritesFilter: false,
      onlyWfhFilter: false,
    );
  }

  Future<void> setUserName(String name) async {
    await PrefsService.setUserName(name);
    state = state.copyWith(userName: name);
    await ProfileRepository().saveProfile(
      ProfileRepository().currentProfile.copyWith(name: name),
    );
  }

  Future<void> setUserEmail(String email) async {
    await PrefsService.setUserEmail(email);
    state = state.copyWith(userEmail: email);
    await ProfileRepository().saveProfile(
      ProfileRepository().currentProfile.copyWith(email: email),
    );
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
    await ProfileRepository().saveProfile(
      ProfileRepository().currentProfile.copyWith(avatarPath: profilePhotoPath),
    );
    await _deleteManagedProfilePhoto(previousPath);
  }

  /// Applies one archive mutation and one provider rebuild for selection mode.
  /// The returned originals can be passed to [restoreJobs] for Undo.
  Future<List<JobApplication>> archiveJobs(Iterable<String> ids) async {
    final selected = ids.toSet();
    final originals = state.jobs
        .where((job) => selected.contains(job.id))
        .toList(growable: false);
    if (originals.isEmpty) return const [];
    final now = DateTime.now();
    final replacements = <String, JobApplication>{
      for (final job in originals)
        job.id: job.copyWith(
          status: 'Dibatalkan',
          closedAt: now,
          updatedAt: now,
        ),
    };
    final box = await _boxReady;
    await box.putAll({
      for (final entry in replacements.entries) entry.key: entry.value.toJson(),
    });
    final updated = _normalizedJobs(
      state.jobs.map((job) => replacements[job.id] ?? job),
    );
    state = state.copyWith(jobs: updated);
    for (final id in selected) {
      _cancelReminderQuietly(id);
    }
    _syncWidgetQuietly(updated);
    return originals;
  }

  Future<void> restoreJobs(Iterable<JobApplication> jobs) async {
    final restored = {for (final job in jobs) job.id: job};
    if (restored.isEmpty) return;
    final box = await _boxReady;
    await box.putAll({
      for (final entry in restored.entries) entry.key: entry.value.toJson(),
    });
    final existingIds = state.jobs.map((job) => job.id).toSet();
    final merged = [
      for (final job in state.jobs) restored[job.id] ?? job,
      for (final job in restored.values)
        if (!existingIds.contains(job.id)) job,
    ];
    final normalized = _normalizedJobs(merged);
    state = state.copyWith(jobs: normalized);
    _syncRemindersQuietly(normalized);
    _syncWidgetQuietly(normalized);
  }

  Future<List<JobApplication>> deleteJobs(Iterable<String> ids) async {
    final selected = ids.toSet();
    final removed = state.jobs
        .where((job) => selected.contains(job.id))
        .toList(growable: false);
    if (removed.isEmpty) return const [];
    final box = await _boxReady;
    await box.deleteAll(selected);
    final updated = state.jobs
        .where((job) => !selected.contains(job.id))
        .toList(growable: false);
    state = state.copyWith(jobs: updated);
    for (final id in selected) {
      _cancelReminderQuietly(id);
    }
    _syncWidgetQuietly(updated);
    return removed;
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
        id: 'sample_idka',
        companyName: 'IDKA Solutions',
        position: 'Digital Marketing',
        status: 'Interview User',
        appliedDate: now.subtract(const Duration(days: 1)),
        salaryOffered: 'Rp 3 jt / bln',
        minSalary: 3000000,
        maxSalary: 3000000,
        workType: 'Hybrid',
        location: 'Yogyakarta',
        jobSource: 'IDKA Portal',
        sourcePlatform: 'IDKA Portal',
        companyLogoPath: 'assets/portal_logos/idka_logo.png',
        jobDescription:
            'Mengelola kampanye pemasaran digital, pembuatan konten kreatif, optimasi media sosial, dan strategi brand IDKA Solutions.',
        isFavorite: true,
        isSampleData: true,
      ),
      JobApplication(
        id: 'sample_nusa',
        companyName: 'Nusa Tech',
        position: 'Flutter Dev',
        status: 'Interview HR',
        appliedDate: now.subtract(const Duration(days: 2)),
        salaryOffered: 'Rp 8–11 jt / bln',
        minSalary: 8000000,
        maxSalary: 11000000,
        workType: 'Hybrid',
        location: 'Jakarta',
        jobSource: 'Glints',
        sourcePlatform: 'Glints',
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
        appliedDate: now.subtract(const Duration(days: 3)),
        salaryOffered: 'Rp 7–10 jt / bln',
        minSalary: 7000000,
        maxSalary: 10000000,
        workType: 'WFO',
        location: 'Bandung',
        jobSource: 'JobStreet',
        sourcePlatform: 'JobStreet',
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
        appliedDate: now.subtract(const Duration(days: 4)),
        salaryOffered: 'Rp 7–9 jt / bln',
        minSalary: 7000000,
        maxSalary: 9000000,
        workType: 'WFH',
        location: 'Remote',
        jobSource: 'LinkedIn',
        sourcePlatform: 'LinkedIn',
        jobDescription:
            'Data dummy untuk mencoba informasi gaji, lokasi, dan mode kerja.',
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
