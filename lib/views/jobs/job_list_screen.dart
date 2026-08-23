import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/company_logo_badge.dart';
import '../../widgets/confused_envelope_mascot.dart';
import '../../widgets/container_morph_route.dart';
import '../../widgets/fly_to_tracker_animator.dart';
import '../../widgets/delight_celebration.dart';
import '../../widgets/welcome_screen_route.dart';
import 'job_detail_screen.dart';
import 'add_edit_job_screen.dart';
import 'job_list_welcome_screen.dart';

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
  final ScrollController _tabScrollController = ScrollController();
  late final List<GlobalKey> _tabKeys;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _addBtnKey = GlobalKey();
  Timer? _debounce;
  int _lastTabIndex = 0;

  String _sortBy = 'Terbaru';
  String _viewMode = 'grid';

  final List<String> _tabs = const [
    'Semua',
    'Contoh',
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
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());
    _tabController.addListener(() {
      if (mounted && _lastTabIndex != _tabController.index) {
        _lastTabIndex = _tabController.index;
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToActiveTab(),
        );
        if (!_tabController.indexIsChanging) {
          unawaited(
            PrefsService.setJobListStatusTab(_tabs[_tabController.index]),
          );
        }
      }
    });
    unawaited(_loadListPreferences());
  }

  Future<void> _loadListPreferences() async {
    final mode = await PrefsService.getJobListViewMode();
    final sort = await PrefsService.getJobListSort();
    final status = await PrefsService.getJobListStatusTab();
    if (!mounted) return;
    final savedTab = _tabs.indexOf(status);
    setState(() {
      _viewMode = mode;
      _sortBy = sort;
      if (savedTab >= 0) _tabController.index = savedTab;
    });
  }

  Future<void> _setViewMode(String mode) async {
    if (_viewMode == mode) return;
    HapticFeedback.selectionClick();
    setState(() => _viewMode = mode);
    await PrefsService.setJobListViewMode(mode);
    if (mounted) {
      AppToast.success(
        context,
        mode == 'grid'
            ? 'Grid menjadi tampilan pilihanmu.'
            : 'List menjadi tampilan pilihanmu.',
      );
    }
  }

  void _scrollToActiveTab() {
    final tabContext = _tabKeys[_tabController.index].currentContext;
    if (tabContext == null) return;
    Scrollable.ensureVisible(
      tabContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _showSortModal(BuildContext context) {
    HapticFeedback.selectionClick();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final sortOptions = [
      {
        'label': 'Terbaru Dilamar',
        'value': 'Terbaru',
        'icon': Icons.schedule_rounded,
      },
      {
        'label': 'Terlama Dilamar',
        'value': 'Terlama',
        'icon': Icons.history_rounded,
      },
      {
        'label': 'Gaji Tertinggi',
        'value': 'Gaji Tertinggi',
        'icon': Icons.monetization_on_outlined,
      },
      {
        'label': 'Jadwal Terdekat',
        'value': 'Deadline Terdekat',
        'icon': Icons.event_available_rounded,
      },
      {
        'label': 'Nama Perusahaan (A-Z)',
        'value': 'Nama Perusahaan (A-Z)',
        'icon': Icons.sort_by_alpha_rounded,
      },
    ];

    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final unselectedBg = isDark
        ? const Color(0xFF282830)
        : const Color(0xFFF3F1EC);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
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
            Text(
              'Urutkan Lamaran',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: txtPri,
              ),
            ),
            const SizedBox(height: 14),
            ...sortOptions.map((opt) {
              final isSel = _sortBy == opt['value'];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFF5C44E4).withValues(alpha: 0.12)
                        : unselectedBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    opt['icon'] as IconData,
                    size: 20,
                    color: isSel
                        ? const Color(0xFF5C44E4)
                        : (isDark ? Colors.white70 : const Color(0xFF121214)),
                  ),
                ),
                title: Text(
                  opt['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel ? const Color(0xFF5C44E4) : txtPri,
                  ),
                ),
                trailing: isSel
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF5C44E4),
                        size: 22,
                      )
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sortBy = opt['value'] as String);
                  unawaited(PrefsService.setJobListSort(_sortBy));
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddJob(BuildContext ctx, [GlobalKey? key]) async {
    final result = await MorphSheetRoute.openMorphingSheet<JobApplication>(
      context: ctx,
      buttonKey: key ?? _addBtnKey,
      child: const AddEditJobScreen(startQuickMode: true),
    );

    if (result != null && mounted) {
      FlyToTrackerAnimator.runFlyAnimation(
        context: context,
        sourceKey: key ?? _addBtnKey,
        companyName: result.companyName,
      );
      DelightCelebration.show(
        context,
        message: 'Lamaran baru masuk ke tracker!',
        accent: const Color(0xFF8B5CF6),
        icon: Icons.inbox_rounded,
        preset: DelightPreset.trackerSave,
      );
      AppToast.success(
        context,
        'Lamaran tersimpan!',
        subtitle: '${result.position} di ${result.companyName}',
        actionLabel: 'Lihat',
        onAction: () {
          if (mounted) {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => JobDetailScreen(job: result)),
            );
          }
        },
      );
    }
  }

  List<JobApplication> _filterJobs(
    List<JobApplication> jobs,
    String category,
    JobState state,
  ) {
    final filtered = jobs.where((job) {
      final q = state.searchQuery.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          job.position.toLowerCase().contains(q) ||
          job.companyName.toLowerCase().contains(q) ||
          (job.location?.toLowerCase().contains(q) ?? false) ||
          (job.notes?.toLowerCase().contains(q) ?? false) ||
          (job.hrContact?.toLowerCase().contains(q) ?? false) ||
          job.jobDescription.toLowerCase().contains(q);

      if (!matchesSearch) return false;
      if (state.onlyFavoritesFilter && !job.isFavorite) return false;
      if (state.onlyWfhFilter &&
          job.workType != 'WFH' &&
          !job.jobDescription.toLowerCase().contains('remote')) {
        return false;
      }

      if (category == 'Semua') return true;
      return job.status == category;
    }).toList();

    // Sort logic
    switch (_sortBy) {
      case 'Terlama':
        filtered.sort((a, b) => a.appliedDate.compareTo(b.appliedDate));
        break;
      case 'Gaji Tertinggi':
        filtered.sort((a, b) => (b.maxSalary ?? 0).compareTo(a.maxSalary ?? 0));
        break;
      case 'Deadline Terdekat':
        filtered.sort((a, b) {
          final aDate = a.interviewDate ?? a.testDate ?? DateTime(2099);
          final bDate = b.interviewDate ?? b.testDate ?? DateTime(2099);
          return aDate.compareTo(bDate);
        });
        break;
      case 'Nama Perusahaan (A-Z)':
        filtered.sort(
          (a, b) => a.companyName.toLowerCase().compareTo(
            b.companyName.toLowerCase(),
          ),
        );
        break;
      case 'Terbaru':
      default:
        filtered.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isDark = AppTheme.isDark(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final purpleGradient = isDark
        ? const [Color(0xFF19142E), Color(0xFF151324), Color(0xFF121214)]
        : const [Color(0xFFEFEAFF), Color(0xFFF7F4FF), Color(0xFFF5EFE6)];
    final jobsByTab = <String, List<JobApplication>>{
      for (final tab in _tabs) tab: _filterJobs(state.jobs, tab, state),
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: purpleGradient,
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Bar: Title + Add Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'LAMARAN\nSAYA',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: txtPri,
                          letterSpacing: -1.2,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        FluidBounceButton(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              WelcomeScreenRoute(
                                child: const JobListWelcomeScreen(),
                              ),
                            );
                          },
                          semanticLabel: 'Buka panduan Lamaran Saya',
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF242428)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF383842)
                                    : const Color(0xFFE5E0D5),
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
                            child: const Icon(
                              CupertinoIcons.question_circle_fill,
                              size: 18,
                              color: Color(0xFF5C44E4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FluidBounceButton(
                          key: _addBtnKey,
                          onTap: () => _openAddJob(context, _addBtnKey),
                          semanticLabel: 'Tambah lamaran',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF5C44E4)
                                  : const Color(0xFF1C1C1E),
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
                      ],
                    ),
                  ],
                ),
              ),

              // Search Box & Quick Filter Pills
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Column(
                  children: [
                    AppSearchField(
                      controller: _searchController,
                      hintText: 'Cari posisi, perusahaan, atau kota...',
                      onClear: () {
                        ref.read(jobProvider.notifier).setSearchQuery('');
                      },
                      onChanged: (v) {
                        if (_debounce?.isActive ?? false) {
                          _debounce!.cancel();
                        }
                        _debounce = Timer(
                          const Duration(milliseconds: 400),
                          () {
                            if (mounted) {
                              ref.read(jobProvider.notifier).setSearchQuery(v);
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildCompactControl(
                              isDark: isDark,
                              active: state.onlyFavoritesFilter,
                              icon: state.onlyFavoritesFilter
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              count: state.favoriteCount,
                              tooltip: 'Bookmark',
                              onTap: () => ref
                                  .read(jobProvider.notifier)
                                  .toggleOnlyFavoritesFilter(),
                            ),
                            const SizedBox(width: 8),
                            _buildCompactControl(
                              isDark: isDark,
                              active: _sortBy != 'Terbaru',
                              icon: Icons.sort_rounded,
                              tooltip: 'Urutan: $_sortBy',
                              onTap: () => _showSortModal(context),
                            ),
                            const SizedBox(width: 8),
                            _buildCompactControl(
                              isDark: isDark,
                              icon: _viewMode == 'grid'
                                  ? Icons.grid_view_rounded
                                  : Icons.view_agenda_outlined,
                              tooltip: _viewMode == 'grid'
                                  ? 'Ubah ke tampilan list'
                                  : 'Ubah ke tampilan grid',
                              onTap: () => _setViewMode(
                                _viewMode == 'grid' ? 'list' : 'grid',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontal Status Tab Bar
              SizedBox(
                height: 44,
                child: SingleChildScrollView(
                  controller: _tabScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final tabName = _tabs[i];
                      final isSelected = _tabController.index == i;
                      final count = jobsByTab[tabName]!.length;

                      return Padding(
                        key: _tabKeys[i],
                        padding: const EdgeInsets.only(right: 8),
                        child: FluidBounceButton(
                          semanticLabel:
                              'Tampilkan status $tabName, $count lamaran',
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _tabController.animateTo(i);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF19191B)
                                  : (isDark
                                        ? const Color(0xFF242428)
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF19191B)
                                    : (isDark
                                          ? const Color(0xFF333338)
                                          : const Color(0xFFE5E0D5)),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tabName != 'Semua') ...[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppTheme.getStatusColor(tabName),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  tabName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF333338)),
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : (isDark
                                                ? const Color(0xFF333338)
                                                : const Color(0xFFF0EBE0)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF555558)),
                                      ),
                                    ),
                                  ),
                                ],
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

              // TabBarView List of Jobs with Swipe-to-Delete
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: List.generate(_tabs.length, (tabIdx) {
                    final category = _tabs[tabIdx];
                    final jobs = jobsByTab[category]!;

                    if (jobs.isEmpty) {
                      return Transform.translate(
                        offset: const Offset(0, -26),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Center(
                                  child: ConfusedEnvelopeMascot(
                                    width: 195,
                                    height: 155,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada lamaranmu di "$category"',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: txtPri,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category == 'Bookmark'
                                      ? 'Tandai lowongan favoritmu agar tersimpan rapi di sini.'
                                      : (category.contains('Interview')
                                            ? 'Belum ada jadwal wawancara aktif. Terus kirim lamaran terbaikmu!'
                                            : 'Catat dan pantau setiap tahapan seleksi kerjamu.'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: txtSec,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (state.searchQuery.isNotEmpty ||
                                        state.onlyFavoritesFilter ||
                                        state.onlyWfhFilter ||
                                        _sortBy != 'Terbaru') ...[
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          _searchController.clear();
                                          ref
                                              .read(jobProvider.notifier)
                                              .resetFilters();
                                          setState(() => _sortBy = 'Terbaru');
                                        },
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 15,
                                        ),
                                        label: const Text(
                                          'Reset Filter',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          side: BorderSide(
                                            color: isDark
                                                ? const Color(0xFF383842)
                                                : const Color(0xFFDCD8CE),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          foregroundColor: txtPri,
                                          backgroundColor: isDark
                                              ? const Color(0xFF242428)
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                    ElevatedButton.icon(
                                      onPressed: () => _openAddJob(context),
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Catat Lamaran',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark
                                            ? const Color(0xFF5C44E4)
                                            : const Color(0xFF19191B),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    if (_viewMode == 'grid') {
                      return GridView.builder(
                        key: PageStorageKey('job_grid_${_tabs[tabIdx]}'),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          120 + MediaQuery.of(context).padding.bottom,
                        ),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent:
                              (226 +
                                      (MediaQuery.textScalerOf(
                                                context,
                                              ).scale(1) -
                                              1) *
                                          56)
                                  .clamp(226, 282),
                        ),
                        itemCount: jobs.length,
                        itemBuilder: (context, i) {
                          final job = jobs[i];
                          final cardColor = AppTheme.getCompanyCardColor(
                            job.companyName,
                            job.status,
                          );
                          final isDarkText =
                              cardColor == AppTheme.cardYellow ||
                              cardColor == AppTheme.cardGreen;
                          return _buildJobGridCard(
                            context: context,
                            job: job,
                            cardColor: cardColor,
                            isDarkText: isDarkText,
                          );
                        },
                      );
                    }

                    return ListView.builder(
                      key: PageStorageKey('job_list_${_tabs[tabIdx]}'),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        120 + MediaQuery.of(context).padding.bottom,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: jobs.length,
                      itemBuilder: (context, i) {
                        final job = jobs[i];
                        final cardColor = AppTheme.getCompanyCardColor(
                          job.companyName,
                          job.status,
                        );
                        final isDarkText =
                            cardColor == AppTheme.cardYellow ||
                            cardColor == AppTheme.cardGreen;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key(job.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              HapticFeedback.heavyImpact();
                              return await AppDialog.show<bool>(
                                context: context,
                                icon: Icons.delete_outline_rounded,
                                iconColor: const Color(0xFFE53935),
                                title: 'Hapus Lamaran?',
                                content:
                                    'Hapus lamaran posisi ${job.position} di ${job.companyName}?',
                                secondaryLabel: 'Batal',
                                primaryLabel: 'Hapus',
                                isDestructive: true,
                              );
                            },
                            onDismissed: (_) {
                              unawaited(
                                ref
                                    .read(jobProvider.notifier)
                                    .deleteJob(job.id),
                              );
                              AppToast.success(
                                context,
                                'Lamaran di ${job.companyName} dihapus.',
                                actionLabel: 'Urungkan',
                                onAction: () => unawaited(
                                  ref.read(jobProvider.notifier).addJob(job),
                                ),
                              );
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusCardLarge,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: _buildJobCard(
                              context: context,
                              job: job,
                              cardColor: cardColor,
                              isDarkText: isDarkText,
                            ),
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
      ),
    );
  }

  Widget _buildJobGridCard({
    required BuildContext context,
    required JobApplication job,
    required Color cardColor,
    required bool isDarkText,
  }) {
    final titleColor = isDarkText ? const Color(0xFF111113) : Colors.white;
    final subColor = isDarkText
        ? const Color(0xB8111113)
        : const Color(0xCFFFFFFF);

    return AppleBouncyCard(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => JobDetailScreen(job: job)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Hero(
                  tag: 'company_logo_${job.id}',
                  child: CompanyLogoBadge(
                    companyName: job.companyName,
                    size: 42,
                    customImagePath: job.companyLogoPath,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(jobProvider.notifier).toggleFavorite(job.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      job.isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: titleColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              job.companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              job.position,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const Spacer(),
            if (job.salaryOffered != null && job.salaryOffered!.isNotEmpty)
              Text(
                job.salaryOffered!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.workType,
                    style: TextStyle(
                      color: subColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: titleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
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

  Widget _buildCompactControl({
    required bool isDark,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
    int? count,
  }) {
    return SizedBox(
      height: 48,
      child: Center(
        child: Semantics(
          button: true,
          selected: active,
          label: tooltip,
          child: Tooltip(
            message: tooltip,
            child: FluidBounceButton(
              onTap: onTap,
              semanticLabel: tooltip,
              selected: active,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: 36,
                constraints: const BoxConstraints(minWidth: 36),
                padding: EdgeInsets.symmetric(
                  horizontal: count == null ? 9 : 10,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF5C44E4)
                      : (isDark
                            ? const Color(0xFF28243A)
                            : const Color(0xFFF4F0FF)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF5C44E4)
                        : (isDark
                              ? const Color(0xFF4B426F)
                              : const Color(0xFFD9CDF8)),
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF5C44E4,
                            ).withValues(alpha: 0.24),
                            blurRadius: 7,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: active
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF5C5360)),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 5),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: active
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF5C5360)),
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
    );
  }

  Widget _buildJobCard({
    required BuildContext context,
    required JobApplication job,
    required Color cardColor,
    required bool isDarkText,
  }) {
    final titleColor = isDarkText ? const Color(0xFF111113) : Colors.white;
    final subColor = isDarkText
        ? const Color(0xCC111113)
        : const Color(0xCCFFFFFF);

    return AppleBouncyCard(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => JobDetailScreen(job: job)),
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
                Hero(
                  tag: 'company_logo_${job.id}',
                  flightShuttleBuilder:
                      (
                        flightContext,
                        animation,
                        flightDirection,
                        fromHeroContext,
                        toHeroContext,
                      ) {
                        return Material(
                          type: MaterialType.transparency,
                          child: toHeroContext.widget,
                        );
                      },
                  child: CompanyLogoBadge(
                    companyName: job.companyName,
                    size: 40,
                    customImagePath: job.companyLogoPath,
                  ),
                ),
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
                Expanded(
                  child: Row(
                    children: [
                      if (job.salaryOffered != null) ...[
                        Flexible(
                          child: Text(
                            job.salaryOffered!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '• ${job.workType}',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
