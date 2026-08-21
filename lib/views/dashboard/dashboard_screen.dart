import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/company_logo_badge.dart';
import '../../widgets/container_morph_route.dart';
import '../../widgets/crying_envelope_mascot.dart';
import '../../services/notification_service.dart';
import '../jobs/add_edit_job_screen.dart';
import '../jobs/job_detail_screen.dart';

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
  int _expandedIndex = 3; // Default kartu paling bawah terbuka
  Timer? _debounce;

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  void _openAddJob(BuildContext ctx, [GlobalKey? key]) async {
    HapticFeedback.mediumImpact();
    final result = await MorphSheetRoute.openMorphingSheet<JobApplication>(
      context: ctx,
      buttonKey: key ?? _addBtnKey,
      child: const AddEditJobScreen(),
    );
    if (result != null && mounted) {
      AppToast.success(context, 'Lamaran ${result.companyName} berhasil dicatat!');
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
            padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset > 0 ? bottomInset + 16 : 24),
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
                        ref.read(jobProvider.notifier).toggleOnlyFavoritesFilter();
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
                  children: [
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
                        ref.read(jobProvider.notifier).setStatusFilter(status);
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

  void _showNotificationCenter(BuildContext context, List<JobApplication> jobs) {
    HapticFeedback.selectionClick();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final now = DateTime.now();
    final upcomingInterviews = jobs.where((j) {
      final date = j.interviewDate ?? j.testDate;
      return date != null && date.isAfter(now) && j.status != 'Ditolak' && j.status != 'Diterima';
    }).toList();

    final followupJobs = jobs.where((j) => j.needsFollowup).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset > 0 ? bottomInset + 16 : 24),
        decoration: const BoxDecoration(
          color: Color(0xFFFBF8F2),
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
                const Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, color: Color(0xFF5C44E4), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Pusat Notifikasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF121214),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF121214)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Uji Coba Notifikasi Button
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD6C8F8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFF5C44E4), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uji Notifikasi Perangkat',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF121214)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kirim tes notifikasi langsung ke status bar HP Anda',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF555558)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      await NotificationService.showInstantNotification(
                        title: '⏰ Pengingat Seleksi Loker',
                        body: 'Notifikasi lokal di HP Android Anda berfungsi dengan lancar! Persiapkan tahapan wawancara berikutnya.',
                      );
                      if (context.mounted) {
                        AppToast.success(context, 'Notifikasi berhasil dikirim ke perangkat!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C44E4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Tes 🔔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'JADWAL & PENGINGAT AKTIF',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5),
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
                    Icon(Icons.check_circle_outline_rounded, size: 36, color: Colors.green.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'Semua Jadwal Rapi!',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF121214)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tidak ada jadwal interview mendesak atau follow-up tertunda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                      CupertinoPageRoute(builder: (_) => JobDetailScreen(job: job)),
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
                          child: const Icon(Icons.event_available_rounded, color: Color(0xFFD97706), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Interview di ${job.companyName}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF121214)),
                              ),
                              Text(
                                '${date.day}/${date.month}/${date.year} • Posisi ${job.position}',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
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
                      CupertinoPageRoute(builder: (_) => JobDetailScreen(job: job)),
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
                          child: const Icon(Icons.mark_email_unread_rounded, color: Color(0xFFE53935), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waktunya Follow-Up ${job.companyName}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF121214)),
                              ),
                              Text(
                                'Sudah > 7 hari sejak melamar posisi ${job.position}',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
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
    const bg = AppTheme.warmBackground;
    const txtPri = AppTheme.textDark;
    const txtSec = AppTheme.textMuted;

    final displayName = state.userName.isNotEmpty ? state.userName : 'Pencari Kerja';
    final greeting = _getTimeGreeting();
    final displayJobs = state.priorityJobs;
    final activeExpandedIndex = displayJobs.isEmpty
        ? 0
        : (_expandedIndex >= displayJobs.length ? displayJobs.length - 1 : _expandedIndex);

    final hasProfilePhoto = state.userProfilePhoto.isNotEmpty && File(state.userProfilePhoto).existsSync();

    final alertCount = state.jobs.where((j) {
      final hasUpcomingInterview = j.interviewDate != null && j.interviewDate!.isAfter(DateTime.now());
      return hasUpcomingInterview || j.needsFollowup;
    }).length;

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
                                  width: 44,
                                  height: 44,
                                  cacheWidth: (44 * MediaQuery.of(context).devicePixelRatio).round(),
                                  cacheHeight: (44 * MediaQuery.of(context).devicePixelRatio).round(),
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

                    // Greeting & User Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: txtSec,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: txtPri,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDCD8CE),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
                          size: 20,
                          color: const Color(0xFF121214),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Circular Notification Bell Button
                    GestureDetector(
                      onTap: () => _showNotificationCenter(context, state.jobs),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFDCD8CE),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 21,
                              color: Color(0xFF121214),
                            ),
                          ),
                          if (alertCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  alertCount > 9 ? '9+' : '$alertCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar (if active)
              if (_isSearchActive) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Cari posisi, perusahaan, atau kota...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF121214)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(jobProvider.notifier).setSearchQuery('');
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E0D5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E0D5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 400), () {
                        if (mounted) {
                          setState(() {});
                          ref.read(jobProvider.notifier).setSearchQuery(v);
                        }
                      });
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── LARGE TITLE & ACTIONS ROW (NO OFFSIDE OVERFLOW) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: const Text(
                        'JELAJAHI\nLOWONGAN',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: txtPri,
                          letterSpacing: -1.2,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Actions: Filter (Atas) & Tambah (Bawah) - Rata Kanan
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Filter Pill Button with Fluid Touch Bounce
                        FluidBounceButton(
                          onTap: () => _showFilterModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (state.selectedStatusFilter != 'Semua' ||
                                        state.onlyFavoritesFilter ||
                                        state.onlyWfhFilter)
                                    ? const Color(0xFF5C44E4)
                                    : const Color(0xFFDCD8CE),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 13,
                                  color: (state.selectedStatusFilter != 'Semua' ||
                                          state.onlyFavoritesFilter ||
                                          state.onlyWfhFilter)
                                      ? const Color(0xFF5C44E4)
                                      : const Color(0xFF121214),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (state.selectedStatusFilter != 'Semua' ||
                                          state.onlyFavoritesFilter ||
                                          state.onlyWfhFilter)
                                      ? 'Filter (Aktif)'
                                      : 'Filter',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: (state.selectedStatusFilter != 'Semua' ||
                                            state.onlyFavoritesFilter ||
                                            state.onlyWfhFilter)
                                        ? const Color(0xFF5C44E4)
                                        : const Color(0xFF121214),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Tambah Capsule Pill Button with Fluid Touch Bounce
                        FluidBounceButton(
                          key: _addBtnKey,
                          onTap: () => _openAddJob(context, _addBtnKey),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF19191B),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 3),
                                Text(
                                  'Tambah',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
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
                        const Text(
                          'Belum Ada Lamaran Aktif',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF121214),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Surat lamaranmu masih sedih nih karena belum dikirim. Yuk mulai cari dan catat lowongan impianmu hari ini!',
                          style: TextStyle(fontSize: 13, color: Color(0xFF707074), height: 1.45),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openAddJob(context),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Catat Lamaran', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF19191B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => widget.onNavigateTab?.call(1), // Navigasi ke Eksplorasi Loker
                              icon: const Icon(Icons.explore_rounded, size: 16, color: Color(0xFF5C44E4)),
                              label: const Text('Cari Lowongan', style: TextStyle(color: Color(0xFF5C44E4), fontSize: 12.5, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFD6C8F8), width: 1.2),
                                backgroundColor: const Color(0xFFF6F2FF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildEdgeToEdgeStackedDeck(displayJobs, activeExpandedIndex),

              // ── TOMBOL PINTAS: LIHAT SEMUA LAMARAN ──
              if (state.jobs.length > 4) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 120 + (MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 0)),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () {
                        widget.onNavigateTab?.call(2); // Navigasi ke Tab Lamaran Lengkap
                      },
                      icon: const Icon(Icons.list_alt_rounded, color: Color(0xFF1C1C1E)),
                      label: Text(
                        'Lihat Seluruh ${state.jobs.length} Lamaran Tersimpan →',
                        style: const TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(height: 120 + (MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 0)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeToEdgeStackedDeck(List<JobApplication> jobs, int activeExpandedIndex) {
    return Column(
      children: List.generate(jobs.length, (index) {
        final job = jobs[index];
        final isExpanded = index == activeExpandedIndex;
        final cardColor = AppTheme.getCompanyCardColor(job.companyName, job.status);
        final isDarkText =
            cardColor == AppTheme.cardYellow || cardColor == AppTheme.cardGreen;
        final titleColor = isDarkText ? const Color(0xFF121214) : Colors.white;

        final isLast = index == jobs.length - 1;
        final topMargin = index == 0 ? 0.0 : -24.0;

        // Cek peringatan pintar H+7 Follow-Up
        final daysSinceApplied = DateTime.now().difference(job.appliedDate).inDays;
        final needsFollowup = job.status == 'Dikirim' && daysSinceApplied >= 7;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            if (isExpanded) {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => JobDetailScreen(job: job),
                ),
              );
            } else {
              setState(() {
                _expandedIndex = index;
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.fastOutSlowIn,
            width: double.infinity,
            margin: EdgeInsets.only(top: topMargin),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(32),
                bottom: isLast || isExpanded
                    ? const Radius.circular(32)
                    : const Radius.circular(0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
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
                  20,
                  22,
                  isExpanded ? 50 : 42,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Logo + Company Name + Smart Alert / Arrow
                    Row(
                      children: [
                        Hero(
                          tag: 'company_logo_${job.id}',
                          flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                            return Material(
                              type: MaterialType.transparency,
                              child: toHeroContext.widget,
                            );
                          },
                          child: CompanyLogoBadge(
                            companyName: job.companyName,
                            size: 42,
                            customImagePath: job.companyLogoPath,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
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

                        // Diagonal Arrow in Circular White Container with Fluid Fade Animation
                        AnimatedOpacity(
                          opacity: isExpanded ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.fastOutSlowIn,
                          child: AnimatedScale(
                            scale: isExpanded ? 0.82 : 1.0,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.fastOutSlowIn,
                            child: IgnorePointer(
                              ignoring: isExpanded,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
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
                            CupertinoPageRoute(
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
                                job.salaryOffered != null && job.salaryOffered!.isNotEmpty
                                    ? job.salaryOffered!
                                    : 'Rp 25.000.000 / bln',
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
                                    color: titleColor.withValues(alpha: 0.85),
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
        );
      }),
    );
  }
}
