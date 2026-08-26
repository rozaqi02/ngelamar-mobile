import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import '../../services/notification_service.dart';
import '../../services/prefs_service.dart';
import '../jobs/add_edit_job_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../notifications/notification_center_screen.dart';

/// Screen 1: Jelajahi Lowongan (Priority Overlapping Deck & Smart Alerts).
class DashboardScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

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

  @override
  void initState() {
    super.initState();
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
    _debounce?.cancel();
    PrefsService.userInterestsListenable.removeListener(_syncProfileSubtitle);
    _searchController.dispose();
    super.dispose();
  }

  void _openAddJob(BuildContext ctx, [GlobalKey? key]) async {
    final result = await Navigator.of(ctx).push<JobApplication>(
      AppMotion.fadeScaleRoute<JobApplication>(
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
        preset: DelightPreset.homeSave,
      );
      AppToast.success(
        context,
        'Lamaran ${result.companyName} berhasil dicatat!',
      );
    }
  }

  void _showFilterModal(BuildContext context) {
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
                        'Semua',
                        'Dikirim',
                        'Tes / Psikotes',
                        'Interview HR',
                        'Interview User',
                        'Offering',
                        'Diterima',
                      ].map((status) {
                        final isSel = currentStatus == status;
                        return ChoiceChip(
                          selected: isSel,
                          label: Text(status),
                          onSelected: (_) {
                            ref
                                .read(jobProvider.notifier)
                                .setStatusFilter(status);
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

    final hasProfilePhoto =
        state.userProfilePhoto.isNotEmpty &&
        File(state.userProfilePhoto).existsSync();

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
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                          child: hasProfilePhoto
                              ? Image.file(
                                  File(state.userProfilePhoto),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  filterQuality: FilterQuality.medium,
                                  width: 44,
                                  height: 44,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
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
                                builder: (_) => const NotificationCenterScreen(),
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
                                if (state.jobs.any((j) =>
                                    (j.interviewDate != null ||
                                        j.testDate != null ||
                                        j.needsFollowup) &&
                                    j.status != 'Ditolak' &&
                                    j.status != 'Diterima'))
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

                        // Circular Search Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isSearchActive = !_isSearchActive;
                              if (!_isSearchActive) {
                                _searchController.clear();
                                ref.read(jobProvider.notifier).setSearchQuery('');
                              }
                            });
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
                            child: Icon(
                              _isSearchActive
                                  ? Icons.close_rounded
                                  : Icons.search_rounded,
                              size: 21,
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

              // ── LARGE TITLE ROW WITH RIGHT-ALIGNED FILTER BUTTON (SESUAI FOTO) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'LIHAT\nLAMARANMU',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: txtPri,
                          letterSpacing: -1.6,
                          height: 0.96,
                        ),
                      ),
                    ),

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
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          size: 19,
                          color: Color(0xFF5C44E4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Filters Pill Button (Sesuai Foto Mockup)
                    FluidBounceButton(
                      onTap: () => _showFilterModal(context),
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(22),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color:
                                  (state.selectedStatusFilter != 'Semua' ||
                                      state.onlyFavoritesFilter ||
                                      state.onlyWfhFilter)
                                  ? const Color(0xFF5C44E4)
                                  : txtPri,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color:
                                    (state.selectedStatusFilter != 'Semua' ||
                                        state.onlyFavoritesFilter ||
                                        state.onlyWfhFilter)
                                    ? const Color(0xFF5C44E4)
                                    : txtPri,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

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
                          'Belum Ada Lamaran Aktif',
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
                          'Surat lamaranmu masih sedih nih karena belum dikirim. Yuk mulai cari dan catat lowongan impianmu hari ini!',
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
                            FluidBounceButton(
                              key: _addBtnKey,
                              onTap: () => _openAddJob(context),
                              child: Hero(
                                tag: 'add_job_action_button',
                                flightShuttleBuilder:
                                    (
                                      flightContext,
                                      animation,
                                      flightDirection,
                                      fromHeroContext,
                                      toHeroContext,
                                    ) => Material(
                                      type: MaterialType.transparency,
                                      child: toHeroContext.widget,
                                    ),
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
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 11),
                            FluidBounceButton(
                              onTap: () => widget.onNavigateTab?.call(3),
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
              else
                _buildEdgeToEdgeStackedDeck(displayJobs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeToEdgeStackedDeck(List<JobApplication> jobs) {
    return Column(
      children: List.generate(jobs.length, (index) {
        final job = jobs[index];
        final isLast = index == jobs.length - 1;
        final isExpanded =
            _expandedIndices.contains(index) ||
            (isLast && !_expandedIndices.contains(-100));
        final cardColor = AppTheme.getCompanyCardColor(
          job.companyName,
          job.status,
        );
        final isDarkText = !AppTheme.isDarkCard(cardColor);
        final titleColor = isDarkText ? const Color(0xFF121214) : Colors.white;

        final minimumLastHeight = (MediaQuery.sizeOf(context).height * 0.38)
            .clamp(280.0, 440.0)
            .toDouble();

        // Cek peringatan pintar H+7 Follow-Up
        final daysSinceApplied = DateTime.now()
            .difference(job.appliedDate)
            .inDays;
        final needsFollowup = job.status == 'Dikirim' && daysSinceApplied >= 7;

        return StaggeredReveal(
          index: index,
          child: Semantics(
            button: true,
            label:
                '${job.companyName}, ${job.position}. ${isExpanded ? 'Terbuka. Ketuk untuk menutup.' : 'Tertutup. Ketuk untuk membuka.'}',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (_expandedIndices.contains(index)) {
                    _expandedIndices.remove(index);
                    if (isLast) {
                      _expandedIndices.add(
                        -100,
                      ); // sentinel to allow closing last card if tapped
                    }
                  } else {
                    _expandedIndices.add(index);
                    if (isLast) {
                      _expandedIndices.remove(-100);
                    }
                  }
                });
              },
              child: OverlapShift(
                isFirst: index == 0,
                overlap: 24.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.fastOutSlowIn,
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: isLast ? minimumLastHeight : 0,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(32),
                      bottom: isLast
                          ? const Radius.circular(32)
                          : const Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.fastOutSlowIn,
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        22,
                        18,
                        22,
                        isLast
                            ? AppLayoutMetrics.contentBottomClearance(context)
                            : (isExpanded ? 48 : 44),
                      ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Row: Logo + Company Name + Smart Alert / Arrow
                        Row(
                          children: [
                            SizedBox.square(
                              dimension: 42,
                              child: Hero(
                                tag: 'company_logo_${job.id}',
                                createRectTween: companyLogoRectTween,
                                flightShuttleBuilder: companyLogoFlightShuttle,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'H+7 Waktunya Follow-Up',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Diagonal Arrow in Circular White Container (Always visible)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.push(
                                  context,
                                  AppMotion.detailDockRoute(
                                    builder: (_) => JobDetailScreen(job: job),
                                  ),
                                );
                              },
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
                          ],
                        ),

                        // Expanded Card Body (Position Title, Salary, Details Button)
                        if (isExpanded) ...[
                          const SizedBox(height: 18),

                          // Position Title
                          Text(
                            job.position,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                              letterSpacing: -0.5,
                              height: 1.18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 14),

                          // Bottom Row: Salary in Rp & Right Chevron >
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                AppMotion.detailDockRoute(
                                  builder: (_) => JobDetailScreen(job: job),
                                ),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    job.salaryOffered != null &&
                                            job.salaryOffered!.isNotEmpty
                                        ? job.salaryOffered!
                                        : 'Gaji belum dicantumkan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: titleColor,
                                      letterSpacing: -0.2,
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
    );
  }
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
    final weekly = jobs
        .where((job) => !job.appliedDate.isBefore(start))
        .toList();
    final interview = jobs
        .where((job) => job.status.startsWith('Interview'))
        .length;
    final followup = jobs.where((job) => job.needsFollowup).length;
    final accepted = jobs.where((job) => job.status == 'Diterima').length;
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

/// Custom SingleChildRenderObjectWidget that reduces layout height by [overlap]
/// and shifts child paint offset upwards by [overlap] for seamless card stacking.
class OverlapShift extends SingleChildRenderObjectWidget {
  final double overlap;
  final bool isFirst;

  const OverlapShift({
    super.key,
    required this.isFirst,
    this.overlap = 24.0,
    required super.child,
  });

  @override
  RenderOverlapShift createRenderObject(BuildContext context) {
    return RenderOverlapShift(isFirst: isFirst, overlap: overlap);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOverlapShift renderObject,
  ) {
    renderObject
      ..isFirst = isFirst
      ..overlap = overlap;
  }
}

class RenderOverlapShift extends RenderShiftedBox {
  bool _isFirst;
  double _overlap;

  RenderOverlapShift({
    RenderBox? child,
    required bool isFirst,
    required double overlap,
  })  : _isFirst = isFirst,
        _overlap = overlap,
        super(child);

  bool get isFirst => _isFirst;
  set isFirst(bool value) {
    if (_isFirst != value) {
      _isFirst = value;
      markNeedsLayout();
    }
  }

  double get overlap => _overlap;
  set overlap(double value) {
    if (_overlap != value) {
      _overlap = overlap;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      final childSize = child!.size;
      final effectiveOverlap = _isFirst ? 0.0 : _overlap;
      size = Size(
        childSize.width,
        (childSize.height - effectiveOverlap).clamp(0.0, double.infinity),
      );
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      childParentData.offset = Offset(0, -effectiveOverlap);
    } else {
      size = Size.zero;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child == null) return false;
    final effectiveOverlap = _isFirst ? 0.0 : _overlap;
    return result.addWithPaintOffset(
      offset: Offset(0, -effectiveOverlap),
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child!.hitTest(result, position: transformed);
      },
    );
  }
}
