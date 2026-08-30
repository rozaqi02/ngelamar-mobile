import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_layout_metrics.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/company_logo_badge.dart';
import '../../widgets/crying_envelope_mascot.dart';
import '../../widgets/fly_to_tracker_animator.dart';
import '../../widgets/delight_celebration.dart';
import '../../widgets/app_motion.dart';
import '../../widgets/safe_avatar_image.dart';
import '../../services/notification_service.dart';
import '../../services/prefs_service.dart';
import 'package:intl/intl.dart';
import '../jobs/add_edit_job_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../notifications/notification_center_screen.dart';

/// Screen 1: Jelajahi Lowongan (Priority Overlapping Deck & Smart Alerts).
class DashboardScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onOpenCareerHub;

  const DashboardScreen({super.key, this.onNavigateTab, this.onOpenCareerHub});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _addBtnKey = GlobalKey();
  bool _isSearchActive = false;
  final Set<int> _expandedIndices = <int>{};
  Timer? _debounce;
  String _profileSubtitle = 'Minat belum dipilih';
  late final AnimationController _deckIntroController;

  @override
  void initState() {
    super.initState();
    _deckIntroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _deckIntroController.forward();
    });

    PrefsService.userInterestsListenable.addListener(_syncProfileSubtitle);
    PrefsService.getUserInterests().then((interests) {
      if (mounted) _applyProfileSubtitle(interests);
    });
  }

  void _syncProfileSubtitle() {
    final interests = PrefsService.userInterestsListenable.value;
    if (interests != null && mounted) _applyProfileSubtitle(interests);
  }

  void _applyProfileSubtitle(List<String> interests) {
    final next = interests.isEmpty ? 'Minat belum dipilih' : interests.first;
    if (_profileSubtitle != next) setState(() => _profileSubtitle = next);
  }

  @override
  void dispose() {
    _deckIntroController.dispose();
    _debounce?.cancel();
    PrefsService.userInterestsListenable.removeListener(_syncProfileSubtitle);
    _searchController.dispose();
    super.dispose();
  }

  void _openAddJob(BuildContext ctx, [GlobalKey? key]) async {
    final result = await Navigator.of(ctx).push<JobApplication>(
      AppMotion.editorRoute<JobApplication>(
        builder: (_) => const AddEditJobScreen(startQuickMode: true),
      ),
    );
    if (result != null && mounted) {
      FlyToTrackerAnimator.runFlyAnimation(
        context: context,
        sourceKey: key ?? _addBtnKey,
        companyName: result.companyName,
      );
      DelightCelebration.show(
        context,
        message: 'Satu langkah lebih dekat ke karier impian!',
        accent: const Color(0xFFF8BA38),
        icon: Icons.rocket_launch_rounded,
        preset: DelightPreset.trackerSave,
      );
      AppToast.success(
        context,
        'Lamaran ${result.companyName} berhasil dicatat!',
      );
    }
  }

  void _showFilterModal(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isWfh = ref.watch(jobProvider).onlyWfhFilter;
          final isFav = ref.watch(jobProvider).onlyFavoritesFilter;
          final currentStatus = ref.watch(jobProvider).selectedStatusFilter;

          return Container(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              bottomInset > 0 ? bottomInset + 16 : 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Lamaran',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF121214),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(jobProvider.notifier).resetFilters();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: Color(0xFF5C44E4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'TIPE KERJA & FAVORIT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      selected: isFav,
                      label: const Text('Bookmark'),
                      onSelected: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        ref
                            .read(jobProvider.notifier)
                            .toggleOnlyFavoritesFilter();
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: isWfh,
                      label: const Text('WFH / Remote'),
                      onSelected: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        ref.read(jobProvider.notifier).toggleOnlyWfhFilter();
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'STATUS TAHAPAN SELEKSI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        'Semua Status',
                        'Dikirim',
                        'Tes / Psikotes',
                        'Interview HR',
                        'Interview User',
                        'Offering',
                        'Diterima',
                      ].map((status) {
                        final filterValue = status == 'Semua Status'
                            ? 'Semua'
                            : status;
                        final isSel = currentStatus == filterValue;
                        return ChoiceChip(
                          selected: isSel,
                          label: Text(status),
                          onSelected: (_) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            ref
                                .read(jobProvider.notifier)
                                .setStatusFilter(filterValue);
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1C1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWeeklyRecap(List<JobApplication> jobs) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WeeklyRecapSheet(jobs: jobs),
    );
  }

  void showNotificationCenter(BuildContext context, List<JobApplication> jobs) {
    HapticFeedback.selectionClick();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final now = DateTime.now();
    final upcomingInterviews = jobs.where((j) {
      final date = j.interviewDate ?? j.testDate;
      return date != null &&
          date.isAfter(now) &&
          j.status != 'Ditolak' &&
          j.status != 'Diterima';
    }).toList();

    final followupJobs = jobs.where((j) => j.needsFollowup).toList();

    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : const Color(0xFFFBF8F2);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF555558);
    final cardBg = isDark ? const Color(0xFF282830) : const Color(0xFFF3EEFF);
    final cardBorder = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFD6C8F8);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          bottomInset > 0 ? bottomInset + 16 : 24,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF5C44E4),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pusat Notifikasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: txtPri,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: txtPri),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Uji Coba Notifikasi Button
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF5C44E4),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uji Notifikasi Perangkat',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: txtPri,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kirim tes notifikasi langsung ke status bar HP Anda',
                          style: TextStyle(fontSize: 11.5, color: txtSec),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      await NotificationService.showInstantNotification(
                        title: 'Pengingat Seleksi Loker',
                        body:
                            'Notifikasi lokal di HP Android Anda berfungsi dengan lancar! Persiapkan tahapan wawancara berikutnya.',
                      );
                      if (context.mounted) {
                        AppToast.success(
                          context,
                          'Notifikasi berhasil dikirim ke perangkat!',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C44E4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Tes Notifikasi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'JADWAL & PENGINGAT AKTIF',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            if (upcomingInterviews.isEmpty && followupJobs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E0D5)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 36,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Semua Jadwal Rapi!',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF121214),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tidak ada jadwal interview mendesak atau follow-up tertunda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ...upcomingInterviews.map((job) {
                final date = job.interviewDate ?? job.testDate!;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      AppMotion.detailDockRoute(
                        builder: (_) => JobDetailScreen(job: job),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E0D5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE8B2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: Color(0xFFD97706),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Interview di ${job.companyName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFF121214),
                                ),
                              ),
                              Text(
                                '${date.day}/${date.month}/${date.year} • Posisi ${job.position}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              ...followupJobs.map((job) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      AppMotion.detailDockRoute(
                        builder: (_) => JobDetailScreen(job: job),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFEBEE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mark_email_unread_rounded,
                            color: Color(0xFFE53935),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waktunya Follow-Up ${job.companyName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFF121214),
                                ),
                              ),
                              Text(
                                'Sudah > 7 hari sejak melamar posisi ${job.position}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isDark = AppTheme.isDark(context);
    final bg = isDark ? const Color(0xFF121214) : AppTheme.warmBackground;
    final txtPri = isDark ? Colors.white : AppTheme.textDark;
    final txtSec = isDark ? const Color(0xFFA0A0A8) : AppTheme.textMuted;

    final displayName = state.userName.isNotEmpty
        ? state.userName
        : 'Pencari Kerja';
    final displayJobs = state.priorityJobs;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP PROFILE & GREETING BAR ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  AppLayoutMetrics.headerTopInsideSafeArea(context),
                  20,
                  0,
                ),
                child: Row(
                  children: [
                    // Profile Avatar with Navigation to Tab 4 (Settings)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onNavigateTab?.call(4);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF333336),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: SafeAvatarImage(
                            imagePath: state.userProfilePhoto,
                            size: 44,
                            displayName: displayName,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Personal identity, kept deliberately minimal.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: txtPri,
                              letterSpacing: -0.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _profileSubtitle,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: txtSec,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Top Right Action Buttons: Notification Bell & Search
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notification Bell Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              AppMotion.detailDockRoute(
                                builder: (_) =>
                                    const NotificationCenterScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF383842)
                                    : const Color(0xFFDCD8CE),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  size: 21,
                                  color: txtPri,
                                ),
                                if (state.jobs.any(
                                  (j) =>
                                      (j.interviewDate != null ||
                                          j.testDate != null ||
                                          j.needsFollowup) &&
                                      j.status != 'Ditolak' &&
                                      j.status != 'Diterima',
                                ))
                                  Positioned(
                                    top: 10,
                                    right: 11,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDE4B3E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Circular Search Button — compact outlined glyph in
                        // the same scale as the visual reference.
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isSearchActive = !_isSearchActive;
                              if (!_isSearchActive) {
                                _searchController.clear();
                                ref
                                    .read(jobProvider.notifier)
                                    .setSearchQuery('');
                              }
                            });
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF383842)
                                    : const Color(0xFFDCD8CE),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isSearchActive
                                  ? Icons.close_rounded
                                  : CupertinoIcons.search,
                              size: 20,
                              color: txtPri,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar with Smooth Expansion Animation
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: _isSearchActive
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: AppSearchField(
                          controller: _searchController,
                          autofocus: true,
                          hintText: 'Cari posisi, perusahaan, atau kota...',
                          onClear: () {
                            ref.read(jobProvider.notifier).setSearchQuery('');
                            setState(() {});
                          },
                          onChanged: (v) {
                            if (_debounce?.isActive ?? false) {
                              _debounce!.cancel();
                            }
                            _debounce = Timer(
                              const Duration(milliseconds: 400),
                              () {
                                if (mounted) {
                                  setState(() {});
                                  ref
                                      .read(jobProvider.notifier)
                                      .setSearchQuery(v);
                                }
                              },
                            );
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 18),

              // Primary heading with vertical icon-only action buttons (Ringkasan over Filter) on the right
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        label: 'Periksa lamaranmu',
                        child: Text(
                          'PERIKSA\nLAMARANMU',
                          maxLines: 2,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: txtPri,
                            letterSpacing: -1.15,
                            height: 0.99,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol Ringkasan (Atas) - Icon Only
                        FluidBounceButton(
                          semanticLabel: 'Buka ringkasan mingguan',
                          onTap: () => _showWeeklyRecap(state.jobs),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF383842)
                                    : const Color(0xFFDCD8CE),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.insights_rounded,
                                size: 20,
                                color: Color(0xFF5C44E4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tombol Filter (Bawah) - Icon Only
                        FluidBounceButton(
                          semanticLabel: 'Buka filter lamaran',
                          onTap: () => _showFilterModal(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    (state.selectedStatusFilter != 'Semua' ||
                                        state.onlyFavoritesFilter ||
                                        state.onlyWfhFilter)
                                    ? const Color(0xFF5C44E4)
                                    : (isDark
                                          ? const Color(0xFF383842)
                                          : const Color(0xFFDCD8CE)),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.tune_rounded,
                                size: 19,
                                color:
                                    (state.selectedStatusFilter != 'Semua' ||
                                        state.onlyFavoritesFilter ||
                                        state.onlyWfhFilter)
                                    ? const Color(0xFF5C44E4)
                                    : txtPri,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Urgent Action Strip (1 compact line ONLY IF URGENT, 0 height otherwise)
              _buildUrgentActionStrip(state.jobs, isDark),

              const SizedBox(height: 20),

              // ── FULL-WIDTH EDGE-TO-EDGE OVERLAPPING CARD STACK ──
              if (displayJobs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(30, 24, 30, 60),
                    child: Column(
                      children: [
                        const CryingEnvelopeMascot(width: 170, height: 130),
                        const SizedBox(height: 14),
                        Text(
                          (state.selectedStatusFilter != 'Semua' ||
                                  state.searchQuery.isNotEmpty ||
                                  state.onlyFavoritesFilter ||
                                  state.onlyWfhFilter ||
                                  state.selectedWorkTypeFilter != 'Semua')
                              ? 'Tidak Ada Hasil yang Cocok'
                              : 'Belum Ada Lamaran Aktif',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF121214),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (state.selectedStatusFilter != 'Semua' ||
                                  state.searchQuery.isNotEmpty ||
                                  state.onlyFavoritesFilter ||
                                  state.onlyWfhFilter ||
                                  state.selectedWorkTypeFilter != 'Semua')
                              ? 'Coba ubah kata kunci pencarian atau bersihkan filter yang sedang aktif.'
                              : 'Surat lamaranmu masih sedih nih karena belum dikirim. Yuk mulai cari dan catat lowongan impianmu hari ini!',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFFA0A0A8)
                                : const Color(0xFF707074),
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Column(
                          children: [
                            if (state.selectedStatusFilter != 'Semua' ||
                                state.searchQuery.isNotEmpty ||
                                state.onlyFavoritesFilter ||
                                state.onlyWfhFilter ||
                                state.selectedWorkTypeFilter != 'Semua') ...[
                              OutlinedButton.icon(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  ref.read(jobProvider.notifier).resetFilters();
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Reset Filter & Pencarian',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  foregroundColor: isDark
                                      ? Colors.white
                                      : const Color(0xFF121214),
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF383842)
                                        : const Color(0xFFDCD8CE),
                                    width: 1.3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            FluidBounceButton(
                              key: _addBtnKey,
                              onTap: () => _openAddJob(context),
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF5C44E4)
                                      : const Color(0xFF19191B),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.16,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 21,
                                    ),
                                    SizedBox(width: 9),
                                    Text(
                                      'Catat Lamaran',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 11),
                            FluidBounceButton(
                              onTap: widget.onOpenCareerHub,
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E8E3E),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1E8E3E,
                                      ).withValues(alpha: 0.24),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.explore_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 9),
                                    Text(
                                      'Cari Lowongan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildEdgeToEdgeStackedDeck(displayJobs),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeToEdgeStackedDeck(List<JobApplication> jobs) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardMinHeight = math.max(320.0, screenHeight * 0.44);
    // A wider reveal between cards gives the deck the calmer breathing room
    // of the reference while preserving its compact layered interaction.
    const collapsedStep = 80.0;
    const expandedStep = 150.0;

    // Calculate Y offsets for each card in the stack
    final yPositions = <double>[];
    double currentY = 0.0;
    for (int i = 0; i < jobs.length; i++) {
      yPositions.add(currentY);
      final isCardExpanded =
          (i == jobs.length - 1) || _expandedIndices.contains(i);
      currentY += isCardExpanded ? expandedStep : collapsedStep;
    }
    final totalStackHeight =
        yPositions.last +
        cardMinHeight +
        AppLayoutMetrics.contentBottomClearance(context) +
        20.0;

    return AnimatedBuilder(
      animation: _deckIntroController,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          curve: Curves.fastOutSlowIn,
          height: totalStackHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(jobs.length, (index) {
              final job = jobs[index];
              final isLast = index == jobs.length - 1;
              final isExpanded = isLast || _expandedIndices.contains(index);
              final rawCardColor = AppTheme.getCompanyCardColor(
                job.companyName,
                job.status,
              );
              // Beranda dan Daftar Lamaran memakai kekuatan warna yang sama
              // di mode terang. Pada mode gelap palet ini sudah menjadi
              // versi yang nyaman dibaca, sehingga tidak diubah lagi.
              final cardColor = rawCardColor;
              final isDarkText = !AppTheme.isDarkCard(cardColor);
              final titleColor = isDarkText
                  ? const Color(0xFF121214)
                  : Colors.white;

              // Staggered cascade entrance from bottom up during initial load
              final start = (index * 0.14).clamp(0.0, 0.55);
              final end = (start + 0.45).clamp(0.0, 1.0);
              final cardProgress = CurvedAnimation(
                parent: _deckIntroController,
                curve: Interval(
                  start,
                  end,
                  curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                ),
              ).value;

              final introSlideY = (1.0 - cardProgress) * 240.0;
              final opacity = cardProgress.clamp(0.0, 1.0);
              final scale = 0.96 + (0.04 * cardProgress);

              // Cek peringatan pintar H+7 Follow-Up
              final daysSinceApplied = DateTime.now()
                  .difference(job.appliedDate)
                  .inDays;
              final needsFollowup =
                  job.status == 'Dikirim' && daysSinceApplied >= 7;

              final targetY = yPositions[index];

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.fastOutSlowIn,
                top: targetY + introSlideY,
                left: 0,
                right: 0,
                height: cardMinHeight,
                child: RepaintBoundary(
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Semantics(
                        button: !isLast,
                        label: isLast
                            ? '${job.companyName}, ${job.position}. Selalu terbuka.'
                            : '${job.companyName}, ${job.position}. ${isExpanded ? 'Terbuka. Ketuk untuk menutup.' : 'Tertutup. Ketuk untuk membuka.'}',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: isLast
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (_expandedIndices.contains(index)) {
                                      _expandedIndices.remove(index);
                                    } else {
                                      _expandedIndices.add(index);
                                    }
                                  });
                                },
                          child: Container(
                            width: double.infinity,
                            height: cardMinHeight,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, -3),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.fromLTRB(
                              20,
                              16,
                              20,
                              isLast
                                  ? math.max(
                                      140.0,
                                      AppLayoutMetrics.contentBottomClearance(
                                            context,
                                          ) +
                                          30,
                                    )
                                  : 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Logo + Company Name + Smart Alert + [ ↗ ] Button
                                Row(
                                  children: [
                                    SizedBox.square(
                                      dimension: 42,
                                      child: Hero(
                                        tag: 'company_logo_${job.id}',
                                        createRectTween: companyLogoRectTween,
                                        flightShuttleBuilder:
                                            companyLogoFlightShuttle,
                                        placeholderBuilder:
                                            companyLogoHeroPlaceholder,
                                        child: CompanyLogoBadge(
                                          companyName: job.companyName,
                                          size: 42,
                                          customImagePath: job.companyLogoPath,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Company Name
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job.companyName,
                                            style: TextStyle(
                                              fontSize: 18.5,
                                              fontWeight: FontWeight.w800,
                                              color: titleColor,
                                              letterSpacing: -0.3,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (needsFollowup) ...[
                                            const SizedBox(height: 2),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFE53935,
                                                ).withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.alarm_rounded,
                                                    size: 11,
                                                    color: Color(0xFFE53935),
                                                  ),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'H+7: Belum ada kabar?',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFFE53935),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Clean Circular White Arrow Button (Directly opens Job Detail Screen)
                                    Semantics(
                                      button: true,
                                      label:
                                          'Buka detail lamaran ${job.companyName}',
                                      child: FluidBounceButton(
                                        semanticLabel:
                                            'Buka detail lamaran ${job.companyName}',
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          Navigator.push(
                                            context,
                                            AppMotion.detailDockRoute(
                                              builder: (_) =>
                                                  JobDetailScreen(job: job),
                                            ),
                                          );
                                        },
                                        child: Hero(
                                          tag: statusActionHeroTag(job.id),
                                          createRectTween:
                                              statusActionRectTween,
                                          flightShuttleBuilder:
                                              statusActionFlightShuttle,
                                          placeholderBuilder:
                                              statusActionHeroPlaceholder,
                                          child: StatusActionHeroMetadata(
                                            isExpanded: false,
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(
                                              0xFF121214,
                                            ),
                                            child: Container(
                                              width: 38,
                                              height: 38,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.arrow_outward_rounded,
                                                  size: 18,
                                                  color: Color(0xFF121214),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Expanded Details: Position, Location, Salary, Details Link
                                if (isExpanded) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    job.position,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: titleColor,
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      Navigator.push(
                                        context,
                                        AppMotion.detailDockRoute(
                                          builder: (_) =>
                                              JobDetailScreen(job: job),
                                        ),
                                      );
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            job.salaryOffered != null &&
                                                    job
                                                        .salaryOffered!
                                                        .isNotEmpty
                                                ? job.salaryOffered!
                                                : 'Gaji belum dicantumkan',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: titleColor.withValues(
                                                alpha: 0.85,
                                              ),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          children: [
                                            Text(
                                              'Lihat Detail',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: titleColor.withValues(
                                                  alpha: 0.85,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              size: 22,
                                              color: titleColor,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildUrgentActionStrip(List<JobApplication> jobs, bool isDark) {
    final actionItems = _buildActionItems(jobs);
    if (actionItems.isEmpty) return const SizedBox.shrink();

    // Pick top urgent item
    final urgentItem = actionItems.first;
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2824) : const Color(0xFFE7DED0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: urgentItem.accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${urgentItem.title}${urgentItem.timeLabel != null ? " · ${urgentItem.timeLabel}" : ""} (${urgentItem.job.companyName})',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: txtPri,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  AppMotion.detailDockRoute(
                    builder: (_) => JobDetailScreen(job: urgentItem.job),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : const Color(0xFF19191B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Buka',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ActionItem> _buildActionItems(List<JobApplication> jobs) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final afterTomorrow = todayStart.add(const Duration(days: 2));
    final weekEnd = todayStart.add(const Duration(days: 7));

    final items = <_ActionItem>[];
    final activeJobs = jobs.where((j) => !j.isClosed).toList();

    for (final job in activeJobs) {
      final interviewAt = job.interviewDate ?? job.testDate;
      if (interviewAt != null) {
        if (interviewAt.isBefore(now)) {
          items.add(
            _ActionItem(
              id: 'act_past_iv_${job.id}',
              category: 'Terlambat',
              type: 'interview',
              title: '${job.status} terlewat',
              subtitle: '${job.position} • ${job.companyName}',
              timeLabel: DateFormat('dd MMM, HH:mm').format(interviewAt),
              job: job,
              accentColor: const Color(0xFFEF4444),
              icon: Icons.warning_amber_rounded,
            ),
          );
        } else if (interviewAt.isBefore(tomorrowStart)) {
          items.add(
            _ActionItem(
              id: 'act_today_iv_${job.id}',
              category: 'Hari Ini',
              type: 'interview',
              title: '${job.status} Hari Ini',
              subtitle: '${job.position} • ${job.companyName}',
              timeLabel: DateFormat('HH:mm').format(interviewAt),
              job: job,
              accentColor: const Color(0xFF5C44E4),
              icon: Icons.event_available_rounded,
            ),
          );
        } else if (interviewAt.isBefore(afterTomorrow)) {
          items.add(
            _ActionItem(
              id: 'act_tmrw_iv_${job.id}',
              category: 'Besok',
              type: 'interview',
              title: '${job.status} Besok',
              subtitle: '${job.position} • ${job.companyName}',
              timeLabel: DateFormat('HH:mm').format(interviewAt),
              job: job,
              accentColor: const Color(0xFF0284C7),
              icon: Icons.event_note_rounded,
            ),
          );
        } else if (interviewAt.isBefore(weekEnd)) {
          items.add(
            _ActionItem(
              id: 'act_week_iv_${job.id}',
              category: 'Minggu Ini',
              type: 'interview',
              title: job.status,
              subtitle: '${job.position} • ${job.companyName}',
              timeLabel: DateFormat(
                'EEEE, dd MMM',
                'id_ID',
              ).format(interviewAt),
              job: job,
              accentColor: const Color(0xFF0D9488),
              icon: Icons.calendar_month_rounded,
            ),
          );
        }
      }

      if (job.nextActionAt != null && job.nextActionType != null) {
        final actAt = job.nextActionAt!;
        if (actAt.isBefore(now)) {
          items.add(
            _ActionItem(
              id: 'act_past_na_${job.id}',
              category: 'Terlambat',
              type: 'next_action',
              title: job.nextActionType!,
              subtitle: '${job.position} • ${job.companyName}',
              timeLabel: DateFormat('dd MMM').format(actAt),
              job: job,
              accentColor: const Color(0xFFF59E0B),
              icon: Icons.assignment_late_rounded,
            ),
          );
        } else if (actAt.isBefore(tomorrowStart)) {
          items.add(
            _ActionItem(
              id: 'act_today_na_${job.id}',
              category: 'Hari Ini',
              type: 'next_action',
              title: job.nextActionType!,
              subtitle: '${job.position} • ${job.companyName}',
              timeLabel: DateFormat('HH:mm').format(actAt),
              job: job,
              accentColor: const Color(0xFF8B5CF6),
              icon: Icons.task_alt_rounded,
            ),
          );
        } else if (actAt.isBefore(weekEnd)) {
          items.add(
            _ActionItem(
              id: 'act_week_na_${job.id}',
              category: 'Minggu Ini',
              type: 'next_action',
              title: job.nextActionType!,
              subtitle: '${job.position} • ${job.companyName}',
              timeLabel: DateFormat('dd MMM').format(actAt),
              job: job,
              accentColor: const Color(0xFF6366F1),
              icon: Icons.schedule_rounded,
            ),
          );
        }
      }

      if (job.needsFollowup && job.nextActionAt == null) {
        final days = job.daysSinceLastActivity;
        items.add(
          _ActionItem(
            id: 'act_follow_${job.id}',
            category: days >= 14 ? 'Terlambat' : 'Minggu Ini',
            type: 'followup',
            title: days >= 14
                ? '$days hari tanpa kabar'
                : 'Waktunya Follow-up (H+$days)',
            subtitle: '${job.position} • ${job.companyName}',
            timeLabel: '$days hari lalu',
            job: job,
            accentColor: days >= 14
                ? const Color(0xFFEA580C)
                : const Color(0xFFD97706),
            icon: Icons.mark_email_unread_rounded,
          ),
        );
      }

      if (job.isDraft) {
        items.add(
          _ActionItem(
            id: 'act_draft_${job.id}',
            category: 'Minggu Ini',
            type: 'draft',
            title: 'Draft Belum Lengkap',
            subtitle:
                '${job.position.isEmpty ? "Posisi" : job.position} • ${job.companyName.isEmpty ? "Perusahaan" : job.companyName}',
            timeLabel: 'Draft',
            job: job,
            accentColor: const Color(0xFF64748B),
            icon: Icons.edit_note_rounded,
          ),
        );
      }
    }

    const rank = {'Terlambat': 0, 'Hari Ini': 1, 'Besok': 2, 'Minggu Ini': 3};
    items.sort(
      (a, b) => (rank[a.category] ?? 4).compareTo(rank[b.category] ?? 4),
    );
    return items;
  }
}

class _ActionItem {
  final String id;
  final String category; // 'Terlambat', 'Hari Ini', 'Besok', 'Minggu Ini'
  final String type; // 'interview', 'test', 'followup', 'draft', 'next_action'
  final String title;
  final String subtitle;
  final String? timeLabel;
  final JobApplication job;
  final Color accentColor;
  final IconData icon;

  const _ActionItem({
    required this.id,
    required this.category,
    required this.type,
    required this.title,
    required this.subtitle,
    this.timeLabel,
    required this.job,
    required this.accentColor,
    required this.icon,
  });
}

class _WeeklyRecapSheet extends StatelessWidget {
  final List<JobApplication> jobs;

  const _WeeklyRecapSheet({required this.jobs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final activeJobs = jobs.toList();
    final weekly = activeJobs
        .where((job) => job.isApplied && !job.appliedDate.isBefore(start))
        .toList();
    final interview = activeJobs.where((job) {
      final schedule = job.interviewDate ?? job.testDate;
      if (schedule != null && !schedule.isBefore(start)) return true;
      return job.recruitmentEvents.any(
        (e) =>
            !e.eventDate.isBefore(start) &&
            (e.type == 'interview' || e.type == 'test'),
      );
    }).length;
    final followup = activeJobs.where((job) => job.needsFollowup).length;
    final accepted = activeJobs
        .where(
          (job) => job.status == 'Diterima' && !job.updatedAt.isBefore(start),
        )
        .length;
    final isDark = AppTheme.isDark(context);
    final background = isDark
        ? const Color(0xFF1E1E24)
        : const Color(0xFFFBF8F2);
    final foreground = isDark ? Colors.white : const Color(0xFF19191B);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFD5CEBF),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'RINGKASAN\nMINGGU INI',
              style: TextStyle(
                fontSize: 28,
                height: .95,
                fontWeight: FontWeight.w900,
                color: foreground,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progres lamaranmu sejak Senin.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : const Color(0xFF6B6B70),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _RecapMetric(
                  label: 'Lamaran baru',
                  value: weekly.length,
                  color: const Color(0xFF5C44E4),
                ),
                const SizedBox(width: 10),
                _RecapMetric(
                  label: 'Interview',
                  value: interview,
                  color: const Color(0xFF0284C7),
                ),
                const SizedBox(width: 10),
                _RecapMetric(
                  label: 'Follow-up',
                  value: followup,
                  color: const Color(0xFFD97706),
                ),
                const SizedBox(width: 10),
                _RecapMetric(
                  label: 'Diterima',
                  value: accepted,
                  color: const Color(0xFF1E8E3E),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _RecapMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, current, _) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Text(
                '${current.round()}',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
