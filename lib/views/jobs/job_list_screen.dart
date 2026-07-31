import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_sheet_window.dart';
import 'job_detail_screen.dart';
import 'add_edit_job_screen.dart';

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
    'Dikirim',
    'Interview & Tes',
    'Offering',
    'Diterima',
    'Ditolak',
  ];

  final List<IconData> _tabIcons = [
    CupertinoIcons.square_grid_2x2,
    CupertinoIcons.paperplane,
    CupertinoIcons.mic,
    CupertinoIcons.gift,
    CupertinoIcons.checkmark_seal,
    CupertinoIcons.xmark_seal,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(jobProvider.notifier)
            .setStatusFilter(_tabs[_tabController.index]);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<JobApplication> _filterJobs(
      List<JobApplication> jobs, String category, JobState state) {
    return jobs.where((job) {
      final q = state.searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          job.position.toLowerCase().contains(q) ||
          job.companyName.toLowerCase().contains(q) ||
          (job.location?.toLowerCase().contains(q) ?? false);

      if (!matchesSearch) return false;
      if (state.onlyFavoritesFilter && !job.isFavorite) return false;
      if (state.onlyWfhFilter && job.workType != 'WFH') return false;

      switch (category) {
        case 'Semua':
          return true;
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final isDark = AppTheme.isDark(context);
    final bg = AppTheme.getBackground(context);
    final txtPri = AppTheme.getTextPrimary(context);

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Apple Large Title
          SliverAppBar(
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            floating: false,
            expandedHeight: 100,
            collapsedHeight: 56,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final topPadding = MediaQuery.of(context).padding.top;
                const collapsedH = 56.0;
                const expandedH = 100.0;
                final available = constraints.maxHeight - topPadding;
                final progress = 1.0 -
                    ((available - collapsedH) / (expandedH - collapsedH))
                        .clamp(0.0, 1.0);

                return Stack(
                  children: [
                    // Large title fades out
                    Positioned(
                      left: 16,
                      bottom: 12,
                      right: 80,
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
                    // Collapsed small title fades in
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
                    // Add button (top-right)
                    Positioned(
                      right: 16,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: () => AppleSheetWindow.showAppleModalSheet(
                          context: context,
                          child: const AddEditJobScreen(),
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: (isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.plus,
                            size: 18,
                            color: isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue,
                          ),
                        ),
                      ),
                    ),
                    // Reset filter button
                    if (state.searchQuery.isNotEmpty ||
                        state.onlyFavoritesFilter ||
                        state.onlyWfhFilter ||
                        state.selectedStatusFilter != 'Semua')
                      Positioned(
                        right: 54,
                        bottom: 14,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(jobProvider.notifier).resetFilters();
                            _tabController.animateTo(0);
                            _searchController.clear();
                          },
                          child: const Text(
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
                );
              },
            ),
          ),

          // Search bar pinned
          SliverPersistentHeader(
            pinned: true,
            delegate: _FixedHeightDelegate(
              height: 56,
              child: ColoredBox(
                color: bg,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        ref.read(jobProvider.notifier).setSearchQuery(v),
                    style: TextStyle(fontSize: 15, color: txtPri),
                    decoration: InputDecoration(
                      hintText: 'Cari posisi, perusahaan...',
                      prefixIcon: Icon(CupertinoIcons.search,
                          color: AppTheme.getTextTertiary(context), size: 17),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                ref
                                    .read(jobProvider.notifier)
                                    .setSearchQuery('');
                              },
                              child: Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  color: AppTheme.getTextTertiary(context),
                                  size: 17),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Quick Filter Chips (Favorit & WFH)
          SliverToBoxAdapter(
            child: ColoredBox(
              color: bg,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                child: Row(
                  children: [
                    _buildPillChip(
                      label: 'Favorit',
                      count: state.favoriteCount,
                      icon: state.onlyFavoritesFilter
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      isActive: state.onlyFavoritesFilter,
                      activeColor: AppTheme.systemOrange,
                      onTap: () => ref
                          .read(jobProvider.notifier)
                          .toggleOnlyFavoritesFilter(),
                    ),
                    const SizedBox(width: 8),
                    _buildPillChip(
                      label: 'WFH',
                      icon: CupertinoIcons.house,
                      isActive: state.onlyWfhFilter,
                      activeColor: AppTheme.systemGreen,
                      onTap: () =>
                          ref.read(jobProvider.notifier).toggleOnlyWfhFilter(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status Category Filter Bar (Pill Chip style matching top filters)
          SliverPersistentHeader(
            pinned: true,
            delegate: _FixedHeightDelegate(
              height: 46,
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
                      final isDark = AppTheme.isDark(context);
                      final statusColor = AppTheme.getStatusColor(category, isDark: isDark);

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildPillChip(
                          label: category,
                          count: count,
                          icon: icon,
                          isActive: isSelected,
                          activeColor: statusColor,
                          onTap: () {
                            _tabController.animateTo(i);
                            ref
                                .read(jobProvider.notifier)
                                .setStatusFilter(category);
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
            if (jobs.isEmpty) return _buildEmpty(category);

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, bottomInset + 100),
              physics: const BouncingScrollPhysics(),
              itemCount: jobs.length,
              itemBuilder: (_, i) => RepaintBoundary(
                child: _buildJobCard(context, jobs[i], ref),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Unified Apple Pill Chip for both Status Tabs & Quick Filters
  Widget _buildPillChip({
    required String label,
    int? count,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final surfSec = AppTheme.getSurfaceSecondary(context);
    final bdr = AppTheme.getBorder(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 12 : 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor : surfSec,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : bdr,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isActive ? Colors.white : txtSec),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: isActive
                  ? Row(
                      children: [
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($count)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        if (count != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($count)',
                            style: TextStyle(
                              color: txtTer,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(
      BuildContext context, JobApplication job, WidgetRef ref) {
    final statusColor = AppTheme.getStatusColor(job.status,
        isDark: AppTheme.isDark(context));
    final daysAgo = DateTime.now().difference(job.appliedDate).inDays;
    final timeStr = daysAgo == 0
        ? 'Hari ini'
        : daysAgo == 1
            ? 'Kemarin'
            : '$daysAgo hr lalu';

    final isInterviewSoon = job.interviewDate != null &&
        job.interviewDate!.isAfter(DateTime.now()) &&
        job.interviewDate!.difference(DateTime.now()).inDays <= 3;

    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);
    final isDark = AppTheme.isDark(context);

    return AppleBouncyCard(
      onTap: () => AppleSheetWindow.showAppleModalSheet(
        context: context,
        child: JobDetailScreen(job: job),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.position,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
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
                              color: txtSec, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              if (isInterviewSoon) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.systemOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.systemOrange.withValues(alpha: 0.25),
                        width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.calendar,
                          color: AppTheme.systemOrange, size: 11),
                      const SizedBox(width: 4),
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

              const SizedBox(height: 10),
              Row(
                children: [
                  _inlineBadge(context, CupertinoIcons.briefcase, job.workType),
                  if (job.location != null) ...[
                    const SizedBox(width: 10),
                    _inlineBadge(context, CupertinoIcons.location, job.location!),
                  ],
                  const Spacer(),
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
                  const SizedBox(width: 10),
                  Text(timeStr,
                      style: TextStyle(
                          color: txtTer, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inlineBadge(BuildContext context, IconData icon, String label) {
    final txtTer = AppTheme.getTextTertiary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: txtTer),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: txtTer, fontSize: 11)),
      ],
    );
  }

  Widget _buildEmpty(String category) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.tray,
              size: 42, color: txtTer),
          const SizedBox(height: 12),
          Text(
            category == 'Semua'
                ? 'Belum Ada Lamaran'
                : 'Tidak ada di "$category"',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: txtPri,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category == 'Semua'
                ? 'Tekan + untuk menambahkan lamaran baru'
                : 'Geser tab untuk melihat kategori lain',
            style: TextStyle(
                color: txtSec, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FixedHeightDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _FixedHeightDelegate({required this.height, required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant _FixedHeightDelegate old) =>
      old.height != height || old.child != child;
}
