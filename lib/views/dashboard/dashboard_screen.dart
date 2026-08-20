import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_sheet_window.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/company_logo_badge.dart';
import '../jobs/add_edit_job_screen.dart';
import '../jobs/job_detail_screen.dart';

/// Screen 1: Jelajahi Lowongan (Priority Overlapping Deck & Smart Alerts).
/// Fitur:
/// - 4 Kartu Prioritas bertumpuk edge-to-edge (0 margin horizontal)
/// - Peringatan pintar: "⏳ Waktunya Follow-Up HR (H+7)" & "🔴 Interview Mendatang"
/// - Tombol "+ Tambah" dan "Filter"
/// - Transisi fluid dan integrasi penuh dengan CRM
class DashboardScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;
  int _expandedIndex = 3; // Default kartu ke-4 terbuka

  void _openAddJob(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final result = await AppleSheetWindow.showAppleModalSheet<JobApplication>(
      context: context,
      child: const AddEditJobScreen(),
    );
    if (result != null && mounted) {
      AppleToast.success(context, 'Lamaran ${result.companyName} berhasil dicatat!');
    }
  }

  void _showFilterModal(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isWfh = ref.watch(jobProvider).onlyWfhFilter;
          final isFav = ref.watch(jobProvider).onlyFavoritesFilter;
          final currentStatus = ref.watch(jobProvider).selectedStatusFilter;

          return Container(
            padding: const EdgeInsets.all(24),
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
                      label: const Text('Hanya Favorit ★'),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    const bg = AppTheme.warmBackground;
    const txtPri = AppTheme.textDark;
    const txtSec = AppTheme.textMuted;

    final displayName = state.userName.isNotEmpty ? state.userName : 'Rizki Pratama';
    const displayRole = 'Pencari Kerja Aktif';

    // Jika sedang mencari, filter dari seluruh database; jika tidak, tampilkan 4 lamaran prioritas!
    final displayJobs = _isSearchActive && state.searchQuery.isNotEmpty
        ? state.jobs.where((job) {
            final q = state.searchQuery.trim().toLowerCase();
            return job.position.toLowerCase().contains(q) ||
                job.companyName.toLowerCase().contains(q) ||
                (job.location?.toLowerCase().contains(q) ?? false);
          }).toList()
        : state.priorityJobs;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP PROFILE BAR ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    // Profile Avatar
                    Container(
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
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User Name & Role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: txtPri,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            displayRole,
                            style: TextStyle(
                              fontSize: 12,
                              color: txtSec,
                              fontWeight: FontWeight.w500,
                            ),
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
                        child: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF121214),
                        ),
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
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) => ref.read(jobProvider.notifier).setSearchQuery(v),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ── LARGE TITLE & ACTIONS ROW ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // JELAJAHI LOWONGAN
                    const Text(
                      'JELAJAHI\nLOWONGAN',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF121214),
                        letterSpacing: -1.2,
                        height: 1.0,
                      ),
                    ),

                    // Actions: [+ Tambah] & [Filter]
                    Row(
                      children: [
                        // "+ Tambah" Action Pill
                        GestureDetector(
                          onTap: () => _openAddJob(context),
                          child: Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Tambah',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // "Filter" Pill Button
                        GestureDetector(
                          onTap: () => _showFilterModal(context),
                          child: Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFDCD8CE),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 15,
                                  color: Color(0xFF121214),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Filter',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF121214),
                                    letterSpacing: -0.2,
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

              const SizedBox(height: 16),

              // ── FULL-WIDTH EDGE-TO-EDGE OVERLAPPING CARD STACK ──
              if (displayJobs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.folder_open_rounded,
                          size: 48,
                          color: Color(0xFF8E8E93),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Belum ada lamaran tersimpan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF121214),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ketuk "+ Tambah" atau cari loker di tab "Cari Loker"!',
                          style: TextStyle(fontSize: 13, color: Color(0xFF707074)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildEdgeToEdgeStackedDeck(displayJobs),

              // ── TOMBOL PINTAS: LIHAT SEMUA LAMARAN ──
              if (state.jobs.length > 4) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
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
                const SizedBox(height: 120),
              ],
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
        final isExpanded = index == _expandedIndex;
        final cardColor = AppTheme.getCompanyCardColor(job.companyName);
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
            setState(() {
              _expandedIndex = index;
            });
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
                        CompanyLogoBadge(
                          companyName: job.companyName,
                          size: 42,
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
                                    '⏳ H+7 Waktunya Follow-Up',
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

                        // Diagonal Arrow in Circular White Container
                        if (!isExpanded)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
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
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(job: job),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              job.salaryOffered != null && job.salaryOffered!.isNotEmpty
                                  ? job.salaryOffered!
                                  : 'Rp 25.000.000 / bln',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                                letterSpacing: -0.2,
                              ),
                            ),
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
