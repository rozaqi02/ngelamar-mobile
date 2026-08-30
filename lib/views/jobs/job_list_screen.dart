import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/job_search_service.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_layout_metrics.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/company_logo_badge.dart';
import '../../widgets/confused_envelope_mascot.dart';
import '../../widgets/fly_to_tracker_animator.dart';
import '../../widgets/delight_celebration.dart';
import '../../widgets/app_motion.dart';
import '../../widgets/welcome_screen_route.dart';
import 'job_detail_screen.dart';
import 'add_edit_job_screen.dart';
import 'job_list_welcome_screen.dart';

/// Full Vacancies / Job Management Screen.
/// Clean, Neo-Modern list with status tabs, quick WFH/Favorite pills, and vibrant company cards.
class JobListScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  const JobListScreen({super.key, this.showBackButton = false});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _addBtnKey = GlobalKey();
  Timer? _debounce;
  int _lastTabIndex = 0;
  bool _isHeaderCollapsed = false;
  final Set<String> _selectedJobIds = <String>{};

  bool get _selectionMode => _selectedJobIds.isNotEmpty;

  String _sortBy = 'Terbaru';
  String _viewMode = 'list';

  final List<String> _tabs = const [
    'Semua',
    'Tersimpan',
    'Draft',
    'Dikirim',
    'Tes / Psikotes',
    'Interview HR',
    'Interview User',
    'Offering',
    'Diterima',
    'Ditolak',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (mounted && _lastTabIndex != _tabController.index) {
        _lastTabIndex = _tabController.index;
        setState(() {});
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

  void _toggleSelection(String jobId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedJobIds.add(jobId)) _selectedJobIds.remove(jobId);
    });
  }

  void _clearSelection() {
    if (_selectedJobIds.isEmpty) return;
    setState(_selectedJobIds.clear);
  }

  Future<void> _archiveSelected() async {
    final originals = await ref
        .read(jobProvider.notifier)
        .archiveJobs(_selectedJobIds);
    if (!mounted || originals.isEmpty) return;
    _clearSelection();
    AppToast.success(
      context,
      '${originals.length} lamaran diarsipkan.',
      actionLabel: 'Urungkan',
      onAction: () =>
          unawaited(ref.read(jobProvider.notifier).restoreJobs(originals)),
    );
  }

  Future<void> _deleteSelected() async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFE53935),
      title: 'Hapus ${_selectedJobIds.length} Lamaran?',
      content: 'Data terpilih akan dihapus dari tracker.',
      secondaryLabel: 'Batal',
      primaryLabel: 'Hapus',
      isDestructive: true,
    );
    if (confirmed != true) return;
    final originals = await ref
        .read(jobProvider.notifier)
        .deleteJobs(_selectedJobIds);
    if (!mounted || originals.isEmpty) return;
    _clearSelection();
    AppToast.success(
      context,
      '${originals.length} lamaran dihapus.',
      actionLabel: 'Urungkan',
      onAction: () =>
          unawaited(ref.read(jobProvider.notifier).restoreJobs(originals)),
    );
  }

  Widget _buildSelectionBar(bool isDark) {
    final textColor = AppTheme.getTextPrimary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242428) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.getBorder(context)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _clearSelection,
              tooltip: 'Batalkan pilihan',
              icon: const Icon(Icons.close_rounded),
            ),
            Expanded(
              child: Text(
                '${_selectedJobIds.length} dipilih',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: _archiveSelected,
              tooltip: 'Arsipkan pilihan',
              icon: const Icon(Icons.archive_outlined),
            ),
            IconButton(
              onPressed: _deleteSelected,
              tooltip: 'Hapus pilihan',
              color: const Color(0xFFE53935),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
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

  void _showFilterModal(BuildContext context, JobState state) {
    HapticFeedback.selectionClick();
    var pendingStatus = _tabs[_tabController.index];
    var pendingWorkType = state.selectedWorkTypeFilter;
    var pendingFavorites = state.onlyFavoritesFilter;
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Filter Lamaran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: txtPri,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tampilkan hanya lamaran yang ingin kamu lihat.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : const Color(0xFF707074),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: isDark ? Colors.white54 : const Color(0xFF77777A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tabs.map((status) {
                      final selected = pendingStatus == status;
                      return ChoiceChip(
                        label: Text(_displayStatus(status)),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) =>
                            setSheetState(() => pendingStatus = status),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF343438)),
                        ),
                        selectedColor: const Color(0xFF19191B),
                        backgroundColor: isDark
                            ? const Color(0xFF282830)
                            : const Color(0xFFF4F1EA),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF19191B)
                              : (isDark
                                    ? const Color(0xFF3A3A42)
                                    : const Color(0xFFE5E0D5)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'TIPE KERJA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: isDark ? Colors.white54 : const Color(0xFF77777A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Semua', 'WFH', 'Hybrid', 'WFO'].map((workType) {
                      final selected = pendingWorkType == workType;
                      return ChoiceChip(
                        label: Text(
                          workType == 'Semua' ? 'Semua tipe' : workType,
                        ),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) =>
                            setSheetState(() => pendingWorkType = workType),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF343438)),
                        ),
                        selectedColor: const Color(0xFF5C44E4),
                        backgroundColor: isDark
                            ? const Color(0xFF282830)
                            : const Color(0xFFF4F1EA),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF5C44E4)
                              : (isDark
                                    ? const Color(0xFF3A3A42)
                                    : const Color(0xFFE5E0D5)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    value: pendingFavorites,
                    onChanged: (value) =>
                        setSheetState(() => pendingFavorites = value),
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: const Color(0xFF5C44E4),
                    title: Text(
                      'Hanya favorit',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: txtPri,
                      ),
                    ),
                    subtitle: Text(
                      'Tampilkan lamaran yang sudah ditandai.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF707074),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setSheetState(() {
                            pendingStatus = 'Semua';
                            pendingWorkType = 'Semua';
                            pendingFavorites = false;
                          }),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: txtPri,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF3A3A42)
                                  : const Color(0xFFDCD8CE),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final current = ref.read(jobProvider);
                            final notifier = ref.read(jobProvider.notifier);
                            notifier.setWorkTypeFilter(pendingWorkType);
                            if (current.onlyFavoritesFilter !=
                                pendingFavorites) {
                              notifier.toggleOnlyFavoritesFilter();
                            }
                            if (current.onlyWfhFilter) {
                              notifier.toggleOnlyWfhFilter();
                            }
                            final statusIndex = _tabs.indexOf(pendingStatus);
                            if (statusIndex >= 0) {
                              _tabController.animateTo(statusIndex);
                            }
                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF19191B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Terapkan',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
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
              AppMotion.detailDockRoute(
                builder: (_) => JobDetailScreen(job: result),
              ),
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
    final filtered = JobSearchService.filterJobs(
      jobs,
      query: state.searchQuery,
      status: category,
      workType: state.selectedWorkTypeFilter,
      onlyFavorites: state.onlyFavoritesFilter,
      onlyWfh: state.onlyWfhFilter,
    );

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
          final aDate =
              a.interviewDate ??
              a.testDate ??
              a.nextActionAt ??
              a.applicationDeadline ??
              DateTime(2099);
          final bDate =
              b.interviewDate ??
              b.testDate ??
              b.nextActionAt ??
              b.applicationDeadline ??
              DateTime(2099);
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

  String _displayStatus(String status) {
    switch (status) {
      case 'Tes / Psikotes':
        return 'Tes & Psikotes';
      case 'Interview HR':
        return 'Wawancara HR';
      case 'Interview User':
        return 'Wawancara User';
      case 'Offering':
        return 'Penawaran';
      default:
        return status;
    }
  }

  Color _getListCardColor(BuildContext context, JobApplication job) {
    final base = AppTheme.getCompanyCardColor(job.companyName, job.status);
    // Mode terang kembali memakai warna status yang kuat agar daftar mudah
    // dipindai. Mode gelap mempertahankan palet yang sudah ada.
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isDark = AppTheme.isDark(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final bg = isDark ? const Color(0xFF121214) : AppTheme.warmBackground;
    final jobsByTab = <String, List<JobApplication>>{
      for (final tab in _tabs) tab: _filterJobs(state.jobs, tab, state),
    };

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectionMode) _clearSelection();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: state.isLoading
            ? const SafeArea(
                child: AppStateView(
                  state: AppViewState.loading,
                  title: 'Menyiapkan lamaranmu',
                  message: 'Data tersimpan sedang dimuat.',
                ),
              )
            : SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // The header leaves entirely while browsing so the list gains real
                    // vertical space; it returns only after the user reaches the top.
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.fastOutSlowIn,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: _isHeaderCollapsed ? 0 : 1,
                          child: Builder(
                            builder: (context) {
                              // SafeArea owns the real Android/iOS notch inset once.
                              // This helper only adds breathing room on-device, while
                              // preserving the simulated mobile notch space on web.
                              final topPad =
                                  AppLayoutMetrics.headerTopInsideSafeArea(
                                    context,
                                    extra: 12,
                                  );
                              return Container(
                                height: 58 + topPad,
                                padding: EdgeInsets.fromLTRB(20, topPad, 20, 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (widget.showBackButton) ...[
                                      FluidBounceButton(
                                        onTap: () =>
                                            Navigator.of(context).maybePop(),
                                        semanticLabel: 'Kembali ke profil',
                                        child: Container(
                                          width: 38,
                                          height: 38,
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
                                          ),
                                          child: Icon(
                                            CupertinoIcons.chevron_back,
                                            size: 18,
                                            color: txtPri,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                      child: Text(
                                        'DAFTAR\nLAMARANKU',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: txtPri,
                                          letterSpacing: -1.0,
                                          height: 1.04,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FluidBounceButton(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            Navigator.push(
                                              context,
                                              WelcomeScreenRoute(
                                                child:
                                                    const JobListWelcomeScreen(),
                                              ),
                                            );
                                          },
                                          semanticLabel:
                                              'Buka panduan Daftar Lamaranku',
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
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
                                                  color: Colors.black
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.2
                                                            : 0.04,
                                                      ),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              CupertinoIcons
                                                  .question_circle_fill,
                                              size: 17,
                                              color: Color(0xFF5C44E4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Search and three contextual controls. Detailed options stay in
                    // the filter sheet so the list remains calm on narrow devices.
                    if (_selectionMode)
                      _buildSelectionBar(isDark)
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                        child: Column(
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.fastOutSlowIn,
                              child: ClipRect(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  heightFactor: _isHeaderCollapsed ? 0 : 1,
                                  child: Column(
                                    children: [
                                      AppSearchField(
                                        controller: _searchController,
                                        hintText:
                                            'Cari posisi, perusahaan, atau kota...',
                                        onClear: () {
                                          ref
                                              .read(jobProvider.notifier)
                                              .setSearchQuery('');
                                        },
                                        onChanged: (v) {
                                          if (_debounce?.isActive ?? false) {
                                            _debounce!.cancel();
                                          }
                                          _debounce = Timer(
                                            const Duration(milliseconds: 400),
                                            () {
                                              if (mounted) {
                                                ref
                                                    .read(jobProvider.notifier)
                                                    .setSearchQuery(v);
                                              }
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF242428)
                                        : const Color(0xFFE8E1D5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.work_outline_rounded,
                                        size: 13,
                                        color: isDark
                                            ? const Color(0xFFA5B4FC)
                                            : const Color(0xFF5C44E4),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${jobsByTab[_tabs[_tabController.index]]!.length} Lamaran',
                                        style: TextStyle(
                                          color: txtPri,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
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
                                const SizedBox(width: 8),
                                _buildCompactControl(
                                  isDark: isDark,
                                  active:
                                      _tabController.index != 0 ||
                                      state.selectedWorkTypeFilter != 'Semua' ||
                                      state.onlyFavoritesFilter ||
                                      state.onlyWfhFilter,
                                  icon: Icons.tune_rounded,
                                  tooltip: 'Filter lamaran',
                                  onTap: () => _showFilterModal(context, state),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 4),

                    // TabBarView List of Jobs with smooth soft cream top fade
                    Expanded(
                      child: Stack(
                        children: [
                          NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollUpdateNotification) {
                                final delta = notification.scrollDelta ?? 0;
                                if (delta > 8 && !_isHeaderCollapsed) {
                                  setState(() => _isHeaderCollapsed = true);
                                } else if (delta < -8 && _isHeaderCollapsed) {
                                  setState(() => _isHeaderCollapsed = false);
                                }
                              } else if (notification.metrics.pixels <= 0 &&
                                  _isHeaderCollapsed) {
                                setState(() => _isHeaderCollapsed = false);
                              }
                              return false;
                            },
                            child: TabBarView(
                              controller: _tabController,
                              physics: const NeverScrollableScrollPhysics(),
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                              textAlign: TextAlign.center,
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
                                                  : (category.contains(
                                                          'Interview',
                                                        )
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
                                                if (state
                                                        .searchQuery
                                                        .isNotEmpty ||
                                                    state.onlyFavoritesFilter ||
                                                    state.onlyWfhFilter ||
                                                    state.selectedWorkTypeFilter !=
                                                        'Semua' ||
                                                    _tabController.index != 0 ||
                                                    _sortBy != 'Terbaru') ...[
                                                  OutlinedButton.icon(
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      ref
                                                          .read(
                                                            jobProvider
                                                                .notifier,
                                                          )
                                                          .resetFilters();
                                                      _tabController.animateTo(
                                                        0,
                                                      );
                                                      setState(
                                                        () =>
                                                            _sortBy = 'Terbaru',
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.refresh_rounded,
                                                      size: 15,
                                                    ),
                                                    label: const Text(
                                                      'Reset Filter',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 10,
                                                          ),
                                                      side: BorderSide(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF383842,
                                                              )
                                                            : const Color(
                                                                0xFFDCD8CE,
                                                              ),
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              18,
                                                            ),
                                                      ),
                                                      foregroundColor: txtPri,
                                                      backgroundColor: isDark
                                                          ? const Color(
                                                              0xFF242428,
                                                            )
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ],
                                                ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _openAddJob(context),
                                                  icon: const Icon(
                                                    Icons.add_rounded,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Catat Lamaran',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: isDark
                                                        ? const Color(
                                                            0xFF5C44E4,
                                                          )
                                                        : const Color(
                                                            0xFF19191B,
                                                          ),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 10,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
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
                                    key: PageStorageKey(
                                      'job_grid_${_tabs[tabIdx]}',
                                    ),
                                    padding: EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      AppLayoutMetrics.contentBottomClearance(
                                        context,
                                      ),
                                    ),
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithMaxCrossAxisExtent(
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
                                      final cardColor = _getListCardColor(
                                        context,
                                        job,
                                      );
                                      final isDarkText = !AppTheme.isDarkCard(
                                        cardColor,
                                      );
                                      return StaggeredReveal(
                                        index: i,
                                        child: _buildJobGridCard(
                                          context: context,
                                          job: job,
                                          cardColor: cardColor,
                                          isDarkText: isDarkText,
                                          selected: _selectedJobIds.contains(
                                            job.id,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }

                                return ListView.builder(
                                  key: PageStorageKey(
                                    'job_list_${_tabs[tabIdx]}',
                                  ),
                                  padding: EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    AppLayoutMetrics.contentBottomClearance(
                                      context,
                                    ),
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: jobs.length,
                                  itemBuilder: (context, i) {
                                    final job = jobs[i];
                                    final cardColor = _getListCardColor(
                                      context,
                                      job,
                                    );
                                    final isDarkText = !AppTheme.isDarkCard(
                                      cardColor,
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: StaggeredReveal(
                                        index: i,
                                        child: Dismissible(
                                          key: Key(job.id),
                                          direction: _selectionMode
                                              ? DismissDirection.none
                                              : DismissDirection.endToStart,
                                          movementDuration: _selectionMode
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 200,
                                                ),
                                          confirmDismiss: (direction) async {
                                            HapticFeedback.heavyImpact();
                                            return await AppDialog.show<bool>(
                                              context: context,
                                              icon:
                                                  Icons.delete_outline_rounded,
                                              iconColor: const Color(
                                                0xFFE53935,
                                              ),
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
                                                ref
                                                    .read(jobProvider.notifier)
                                                    .addJob(job),
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
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusCardLarge,
                                                  ),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
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
                                            selected: _selectedJobIds.contains(
                                              job.id,
                                            ),
                                          ),
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
    required bool selected,
  }) {
    final titleColor = isDarkText ? const Color(0xFF111113) : Colors.white;
    final subColor = isDarkText
        ? const Color(0xB8111113)
        : const Color(0xCFFFFFFF);

    return AppleBouncyCard(
      selected: selected,
      onLongPress: () => _toggleSelection(job.id),
      onTap: () => _selectionMode
          ? _toggleSelection(job.id)
          : Navigator.push(
              context,
              AppMotion.detailDockRoute(
                builder: (_) => JobDetailScreen(job: job),
              ),
            ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
          border: selected ? Border.all(color: Colors.white, width: 3) : null,
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
                  createRectTween: companyLogoRectTween,
                  flightShuttleBuilder: companyLogoFlightShuttle,
                  placeholderBuilder: companyLogoHeroPlaceholder,
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
            Row(
              children: [
                Expanded(
                  child: Text(
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
                ),
                if (job.isSampleData) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5.5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkText
                          ? Colors.black.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Contoh',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ],
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
                if (job.pdfCvPath != null && job.pdfCvPath!.isNotEmpty) ...[
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 13,
                    color: titleColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                ],
                if (job.isGhosted) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${job.daysSinceApplied}h',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkText
                        ? Colors.black.withValues(alpha: 0.07)
                        : Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.5,
                        height: 5.5,
                        decoration: BoxDecoration(
                          color: AppTheme.getStatusColor(job.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _displayStatus(job.status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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
                      ? (isDark
                            ? const Color(0xFFEEEAFB)
                            : const Color(0xFF1C1C1E))
                      : (isDark ? const Color(0xFF282830) : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active
                        ? (isDark
                              ? const Color(0xFFEEEAFB)
                              : const Color(0xFF1C1C1E))
                        : (isDark
                              ? const Color(0xFF383842)
                              : const Color(0xFFE6E1D8)),
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 7,
                            offset: const Offset(0, 2),
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
                          ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
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
                              ? (isDark
                                    ? const Color(0xFF1C1C1E)
                                    : Colors.white)
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
    required bool selected,
  }) {
    final titleColor = isDarkText ? const Color(0xFF111113) : Colors.white;
    final subColor = isDarkText
        ? const Color(0xCC111113)
        : const Color(0xCCFFFFFF);

    return AppleBouncyCard(
      selected: selected,
      onLongPress: () => _toggleSelection(job.id),
      onTap: () => _selectionMode
          ? _toggleSelection(job.id)
          : Navigator.push(
              context,
              AppMotion.detailDockRoute(
                builder: (_) => JobDetailScreen(job: job),
              ),
            ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
          border: selected ? Border.all(color: Colors.white, width: 3) : null,
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
                  createRectTween: companyLogoRectTween,
                  flightShuttleBuilder: companyLogoFlightShuttle,
                  placeholderBuilder: companyLogoHeroPlaceholder,
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
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
                          ),
                          if (job.isSampleData) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkText
                                    ? Colors.black.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Contoh',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                Hero(
                  tag: statusActionHeroTag(job.id),
                  createRectTween: statusActionRectTween,
                  flightShuttleBuilder: statusActionFlightShuttle,
                  placeholderBuilder: statusActionHeroPlaceholder,
                  child: StatusActionHeroMetadata(
                    isExpanded: false,
                    backgroundColor: isDarkText
                        ? const Color(0xFF111113)
                        : Colors.white,
                    foregroundColor: isDarkText ? Colors.white : cardColor,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDarkText
                            ? const Color(0xFF111113)
                            : Colors.white,
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
                      if (job.salaryOffered != null &&
                          job.salaryOffered!.isNotEmpty) ...[
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
                        Text(
                          '• ${job.workType}',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ] else ...[
                        Text(
                          job.workType,
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (job.pdfCvPath != null && job.pdfCvPath!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: isDarkText
                              ? Colors.black.withValues(alpha: 0.10)
                              : Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 12,
                              color: titleColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'CV',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (job.isGhosted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade800.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: titleColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${job.daysSinceApplied}h tanpa respon',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkText
                            ? Colors.black.withValues(alpha: 0.07)
                            : Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              color: AppTheme.getStatusColor(job.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _displayStatus(job.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
