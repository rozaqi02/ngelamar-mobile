import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_sheet_window.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/apple_inline_badge.dart';
import 'job_detail_screen.dart';
import 'add_edit_job_screen.dart';
import '../prep/fresh_grad_prep_screen.dart';

/// Overhauled Apple iOS 18 JobListScreen layout.
/// Features iOS native search header, company monogram avatar badges,
/// consolidated status & quick filter pill bar, and grouped card list architecture.
class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final List<String> _tabs = [
    'Semua',
    'Favorit',
    'WFH',
    'Dikirim',
    'Interview & Tes',
    'Offering',
    'Diterima',
    'Ditolak',
  ];

  final List<IconData> _tabIcons = [
    CupertinoIcons.square_grid_2x2,
    CupertinoIcons.star_fill,
    CupertinoIcons.house_fill,
    CupertinoIcons.paperplane_fill,
    CupertinoIcons.mic_fill,
    CupertinoIcons.gift_fill,
    CupertinoIcons.checkmark_seal_fill,
    CupertinoIcons.xmark_seal_fill,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<JobApplication> _filterJobs(
    List<JobApplication> jobs,
    String category,
    JobState state,
  ) {
    return jobs.where((job) {
      final q = state.searchQuery.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          job.position.toLowerCase().contains(q) ||
          job.companyName.toLowerCase().contains(q) ||
          (job.location?.toLowerCase().contains(q) ?? false);

      if (!matchesSearch) return false;

      switch (category) {
        case 'Semua':
          return true;
        case 'Favorit':
          return job.isFavorite;
        case 'WFH':
          return job.workType == 'WFH';
        case 'Dikirim':
          return job.status == 'Dikirim';
        case 'Interview & Tes':
          return job.status == 'HR Screening' ||
              job.status == 'Tes / Psikotes' ||
              job.status.contains('Interview');
        case 'Offering':
          return job.status == 'Offering';
        case 'Diterima':
          return job.status == 'Diterima';
        case 'Ditolak':
          return job.status == 'Ditolak';
        default:
          return true;
      }
    }).toList();
  }

  int _getCategoryCount(String category, JobState state) {
    switch (category) {
      case 'Semua':
        return state.totalCount;
      case 'Favorit':
        return state.favoriteCount;
      case 'WFH':
        return state.jobs.where((j) => j.workType == 'WFH').length;
      case 'Dikirim':
        return state.appliedCount;
      case 'Interview & Tes':
        return state.interviewCount;
      case 'Offering':
        return state.offeringCount;
      case 'Diterima':
        return state.acceptedCount;
      case 'Ditolak':
        return state.rejectedCount;
      default:
        return 0;
    }
  }

  String _getMonogram(String companyName) {
    final clean = companyName.trim();
    if (clean.isEmpty) return 'JOB';
    final words = clean.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  List<Color> _getGradientForCompany(String companyName) {
    final hash = companyName.codeUnits.fold(0, (prev, elem) => prev + elem);
    final index = hash % 5;
    switch (index) {
      case 0:
        return const [AppTheme.systemBlue, AppTheme.systemIndigo];
      case 1:
        return const [AppTheme.systemTeal, AppTheme.systemBlue];
      case 2:
        return const [AppTheme.systemOrange, AppTheme.systemRed];
      case 3:
        return const [AppTheme.systemPurple, AppTheme.systemIndigo];
      default:
        return const [AppTheme.systemGreen, AppTheme.systemTeal];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isDark = AppTheme.isDark(context);
    final bg = AppTheme.getBackground(context);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final txtPri = AppTheme.getTextPrimary(context);
    final compact =
        MediaQuery.sizeOf(context).width < 390 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final hasActiveFilter =
        state.searchQuery.isNotEmpty || _tabController.index != 0;

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Apple iOS 18 Navigation Header
          SliverAppBar(
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            floating: false,
            expandedHeight: 104,
            collapsedHeight: 56,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final topPadding = MediaQuery.of(context).padding.top;
                const collapsedH = 56.0;
                const expandedH = 104.0;
                final available = constraints.maxHeight - topPadding;
                final progress =
                    1.0 -
                    ((available - collapsedH) / (expandedH - collapsedH)).clamp(
                      0.0,
                      1.0,
                    );

                return Stack(
                  children: [
                    // Large title (fades out on scroll)
                    Positioned(
                      left: 16,
                      bottom: 12,
                      right: 110,
                      child: Opacity(
                        opacity: (1.0 - progress * 2.5).clamp(0.0, 1.0),
                        child: Text(
                          'Lamaran',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: txtPri,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    ),
                    // Collapsed small title (fades in on scroll)
                    Positioned(
                      left: 16,
                      bottom: 14,
                      child: Opacity(
                        opacity: ((progress - 0.6) * 3.0).clamp(0.0, 1.0),
                        child: Text(
                          'Lamaran',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: txtPri,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    // Top-Right Actions (Reset + Offer Comparison + Add Button)
                    Positioned(
                      right: 16,
                      bottom: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.offeringCount >= 2) ...[
                            GestureDetector(
                              onTap: () {
                                AppleSheetWindow.showAppleModalSheet(
                                  context: context,
                                  child: const FreshGradPrepScreen(),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.systemPurple.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.gift_fill,
                                      color: AppTheme.systemPurple,
                                      size: 13,
                                    ),
                                    SizedBox(width: 4),
                                    if (!compact)
                                      Text(
                                        'Bandingkan',
                                        style: TextStyle(
                                          color: AppTheme.systemPurple,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (hasActiveFilter) ...[
                            GestureDetector(
                              onTap: () {
                                ref.read(jobProvider.notifier).resetFilters();
                                _tabController.animateTo(0);
                                _searchController.clear();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: compact
                                    ? Icon(
                                        CupertinoIcons.arrow_counterclockwise,
                                        color: AppTheme.systemBlue,
                                        size: 18,
                                      )
                                    : Text(
                                        'Reset',
                                        style: TextStyle(
                                          color: AppTheme.systemBlue,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                          GestureDetector(
                            onTap: () => _openAddJob(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? AppTheme.systemBlue
                                            : AppTheme.lSystemBlue)
                                        .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.plus,
                                size: 18,
                                color: isDark
                                    ? AppTheme.systemBlue
                                    : AppTheme.lSystemBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Pinned Cupertino Search Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _FixedHeightDelegate(
              height: 54,
              child: ColoredBox(
                color: bg,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        ref.read(jobProvider.notifier).setSearchQuery(v),
                    placeholder: 'Cari posisi, perusahaan, atau kota...',
                    style: TextStyle(fontSize: 14, color: txtPri),
                    placeholderStyle: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getTextTertiary(context),
                    ),
                    backgroundColor: AppTheme.getSurfaceSecondary(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Consolidated Status & Category Filter Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _FixedHeightDelegate(
              height: 48,
              child: Container(
                color: bg,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final category = _tabs[i];
                      final isSelected = _tabController.index == i;
                      final icon = _tabIcons[i];
                      final count = _getCategoryCount(category, state);
                      final statusColor = category == 'Favorit'
                          ? AppTheme.systemOrange
                          : category == 'WFH'
                          ? AppTheme.systemGreen
                          : AppTheme.getStatusColor(category, isDark: isDark);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryPill(
                          label: category,
                          count: count,
                          icon: icon,
                          isSelected: isSelected,
                          activeColor: statusColor,
                          onTap: () {
                            _tabController.animateTo(i);
                            setState(() {});
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: _tabs.map((category) {
            final jobs = _filterJobs(state.jobs, category, state);
            if (jobs.isEmpty) return _buildEmptyState(category);

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 100),
              physics: const BouncingScrollPhysics(),
              itemCount: jobs.length,
              itemBuilder: (_, i) => RepaintBoundary(
                child: _buildOverhauledJobCard(context, jobs[i], ref),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Apple iOS 18 Pill Filter Chip
  Widget _buildCategoryPill({
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final surfSec = AppTheme.getSurfaceSecondary(context);
    final bdr = AppTheme.getBorder(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : surfSec,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : bdr,
            width: AppTheme.borderHairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : activeColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : txtSec,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : activeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 40x Better Apple Grouped Job Card
  Widget _buildOverhauledJobCard(
    BuildContext context,
    JobApplication job,
    WidgetRef ref,
  ) {
    final isDark = AppTheme.isDark(context);
    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);
    final statusColor = AppTheme.getStatusColor(job.status, isDark: isDark);
    final gradientColors = _getGradientForCompany(job.companyName);
    final monogram = _getMonogram(job.companyName);

    final diffDays = DateTime.now().difference(job.appliedDate).inDays;
    final daysAgo = diffDays < 0 ? 0 : diffDays;
    final timeStr = daysAgo == 0
        ? 'Hari ini'
        : daysAgo == 1
        ? 'Kemarin'
        : '$daysAgo hr lalu';

    final isInterviewSoon =
        job.interviewDate != null &&
        job.interviewDate!.isAfter(DateTime.now()) &&
        job.interviewDate!.difference(DateTime.now()).inDays <= 3;

    return RepaintBoundary(
      child: AppleBouncyCard(
        onTap: () => AppleSheetWindow.showAppleModalSheet(
          context: context,
          child: JobDetailScreen(job: job),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: surf,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Monogram Avatar + Position/Company + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monogram Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          monogram,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Position & Company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.position,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                              color: txtPri,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.companyName,
                            style: TextStyle(
                              color: txtSec,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                job.status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Interview Reminder Banner if soon
                if (isInterviewSoon) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.systemOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.systemOrange.withValues(alpha: 0.25),
                        width: AppTheme.borderHairline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.time_solid,
                          color: AppTheme.systemOrange,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Interview ${job.interviewDate!.difference(DateTime.now()).inDays == 0 ? "hari ini!" : "${job.interviewDate!.difference(DateTime.now()).inDays} hr lagi"}',
                          style: const TextStyle(
                            color: AppTheme.systemOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Bottom Row: WorkType & Location badges + Favorite toggle + Date
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          AppleInlineBadge(
                            icon: job.workType == 'WFH'
                                ? CupertinoIcons.house_fill
                                : CupertinoIcons.briefcase_fill,
                            label: job.workType,
                            color: job.workType == 'WFH'
                                ? AppTheme.systemGreen
                                : txtTer,
                          ),
                          if (job.location != null)
                            AppleInlineBadge(
                              icon: CupertinoIcons.location_fill,
                              label: job.location!,
                              color: txtTer,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Favorite toggle button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          ref.read(jobProvider.notifier).toggleFavorite(job.id),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          job.isFavorite
                              ? CupertinoIcons.star_fill
                              : CupertinoIcons.star,
                          color: job.isFavorite
                              ? AppTheme.systemOrange
                              : txtTer,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Relative time badge
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: txtTer,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Apple Contextual Empty State
  Widget _buildEmptyState(String category) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceSecondary(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category == 'Favorit'
                    ? CupertinoIcons.star
                    : category == 'WFH'
                    ? CupertinoIcons.house
                    : CupertinoIcons.tray,
                size: 30,
                color: txtTer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category == 'Semua'
                  ? 'Belum Ada Lamaran'
                  : 'Tidak Ada Lamaran di "$category"',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: txtPri,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              category == 'Semua'
                  ? 'Mulai catat lamaran kerjamu dengan menekan tombol +'
                  : 'Geser filter atau reset pencarian untuk melihat lamaran lain.',
              style: TextStyle(color: txtSec, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppleBouncyCard(
              onTap: () => _openAddJob(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.systemBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.plus, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Tambah Lamaran',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddJob(BuildContext context) async {
    final savedJob = await AppleSheetWindow.showAppleModalSheet<JobApplication>(
      context: context,
      child: const AddEditJobScreen(),
    );

    if (savedJob != null && context.mounted) {
      AppleToast.success(
        context,
        'Lamaran Tersimpan',
        subtitle: '${savedJob.position} @ ${savedJob.companyName}',
        actionLabel: 'Lihat',
        onAction: () => AppleSheetWindow.showAppleModalSheet(
          context: context,
          child: JobDetailScreen(job: savedJob),
        ),
      );
    }
  }
}

class _FixedHeightDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _FixedHeightDelegate({required this.height, required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant _FixedHeightDelegate old) =>
      old.height != height || old.child != child;
}
