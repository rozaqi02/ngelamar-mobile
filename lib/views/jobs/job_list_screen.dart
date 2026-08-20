import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_sheet_window.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/company_logo_badge.dart';
import 'job_detail_screen.dart';
import 'add_edit_job_screen.dart';

/// Full Vacancies / Job Management Screen.
/// Clean, Neo-Modern list with status tabs, quick WFH/Favorite pills, and vibrant company cards.
class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = const [
    'Semua',
    'Dikirim',
    'Tes / Psikotes',
    'Interview HR',
    'Interview User',
    'Offering',
    'Diterima',
    'Ditolak',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddJob(BuildContext context) async {
    final result = await AppleSheetWindow.showAppleModalSheet<JobApplication>(
      context: context,
      child: const AddEditJobScreen(),
    );

    if (result != null && mounted) {
      AppleToast.success(
        context,
        'Lamaran tersimpan!',
        subtitle: '${result.position} di ${result.companyName}',
        actionLabel: 'Lihat',
        onAction: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => JobDetailScreen(job: result),
            ),
          );
        },
      );
    }
  }

  List<JobApplication> _filterJobs(List<JobApplication> jobs, String category, JobState state) {
    return jobs.where((job) {
      final q = state.searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          job.position.toLowerCase().contains(q) ||
          job.companyName.toLowerCase().contains(q) ||
          (job.location?.toLowerCase().contains(q) ?? false);

      if (!matchesSearch) return false;
      if (state.onlyFavoritesFilter && !job.isFavorite) return false;
      if (state.onlyWfhFilter && job.workType != 'WFH') return false;

      if (category == 'Semua') return true;
      return job.status == category;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isDark = AppTheme.isDark(context);
    final bg = AppTheme.getBackground(context);
    final txtPri = AppTheme.getTextPrimary(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar: Title + Add Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DAFTAR\nLAMARAN',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: txtPri,
                      letterSpacing: -1.2,
                      height: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openAddJob(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          Icon(Icons.add_rounded, size: 16, color: Colors.white),
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
                ],
              ),
            ),

            // Search Box
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Cari posisi, perusahaan, atau kota...',
                onChanged: (v) => ref.read(jobProvider.notifier).setSearchQuery(v),
                backgroundColor: isDark ? const Color(0xFF242428) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            // Horizontal Status Tab Bar
            SizedBox(
              height: 44,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final tabName = _tabs[i];
                    final isSelected = _tabController.index == i;
                    final count = _filterJobs(state.jobs, tabName, state).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _tabController.animateTo(i);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF19191B)
                                : (isDark ? const Color(0xFF242428) : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF19191B)
                                  : (isDark ? const Color(0xFF383840) : const Color(0xFFE6E3D8)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tabName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF333333)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : Colors.black.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // TabBarView List of Jobs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: List.generate(_tabs.length, (tabIdx) {
                  final category = _tabs[tabIdx];
                  final jobs = _filterJobs(state.jobs, category, state);

                  if (jobs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.tray, size: 44, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada lamaran di kategori "$category"',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: txtPri,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    physics: const BouncingScrollPhysics(),
                    itemCount: jobs.length,
                    itemBuilder: (context, i) {
                      final job = jobs[i];
                      final cardColor = AppTheme.getCompanyCardColor(job.companyName);
                      final isDarkText = cardColor == AppTheme.cardYellow || cardColor == AppTheme.cardGreen;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildJobCard(
                          context: context,
                          job: job,
                          cardColor: cardColor,
                          isDarkText: isDarkText,
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard({
    required BuildContext context,
    required JobApplication job,
    required Color cardColor,
    required bool isDarkText,
  }) {
    final titleColor = isDarkText ? const Color(0xFF111113) : Colors.white;
    final subColor = isDarkText ? const Color(0xCC111113) : const Color(0xCCFFFFFF);

    return AppleBouncyCard(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => JobDetailScreen(job: job),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CompanyLogoBadge(companyName: job.companyName, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.companyName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        job.position,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDarkText ? const Color(0xFF111113) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.arrow_up_right,
                      size: 16,
                      color: isDarkText ? Colors.white : cardColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (job.salaryOffered != null) ...[
                      Text(
                        job.salaryOffered!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '• ${job.workType}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkText
                        ? Colors.black.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
