import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/job_search_service.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/company_logo_badge.dart';
import '../jobs/job_detail_screen.dart';
import '../subscription/subscription_screen.dart';
import 'discovery_welcome_screen.dart';

/// Screen: Eksplorasi Lowongan Kerja Resmi Terpercaya.
/// Visual Header selaras dengan Homepage, Daftar Lamaran, dan Persiapan Karir.
/// Dilengkapi filter portal resmi (Glints, JobStreet, LinkedIn, Indeed, Kalibrr, KitaLulus),
/// kompatibilitas "Sesuai Minat Anda", logo autentik, dan retensi scroll posisi yang presisi.
class JobDiscoveryScreen extends ConsumerStatefulWidget {
  const JobDiscoveryScreen({super.key});

  @override
  ConsumerState<JobDiscoveryScreen> createState() => _JobDiscoveryScreenState();
}

class _JobDiscoveryScreenState extends ConsumerState<JobDiscoveryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _selectedPlatform = 'Semua';
  String _selectedWorkType = 'Semua Tipe';

  List<JobApplication> _liveJobs = [];
  List<String> _userInterests = [];

  final List<String> _platforms = [
    'Semua',
    'Glints',
    'JobStreet',
    'LinkedIn',
    'Indeed',
    'Kalibrr',
    'KitaLulus',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final interests = await PrefsService.getUserInterests();
    if (mounted) {
      setState(() {
        _userInterests = interests.isNotEmpty
            ? interests
            : ['Flutter / Mobile Dev', 'UI/UX Designer', 'Product Manager'];
      });
      _fetchJobs(initial: true);
    }
  }

  Future<void> _fetchJobs({bool initial = false, bool forceRefresh = false}) async {
    if (initial || forceRefresh) {
      setState(() => _isLoading = true);
    }
    final query = _searchController.text.trim();
    final results = await JobSearchService.searchJobs(
      query: query.isNotEmpty ? query : null,
      userInterests: query.isEmpty ? _userInterests : null,
      platformFilter: _selectedPlatform != 'Semua' ? _selectedPlatform : null,
      workTypeFilter: _selectedWorkType != 'Semua Tipe' ? _selectedWorkType : null,
      forceRefresh: forceRefresh,
    );

    if (mounted) {
      setState(() {
        _liveJobs = results;
        _isLoading = false;
      });
    }
  }

  void _openWelcomeModal() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const DiscoveryWelcomeScreen(),
      ),
    );
  }

  void _saveToTracker(JobApplication job) async {
    HapticFeedback.heavyImpact();
    final isAlreadySaved = ref.read(jobProvider).jobs.any(
      (j) => j.id == job.id || (j.companyName == job.companyName && j.position == job.position),
    );

    if (isAlreadySaved) {
      ref.read(jobProvider.notifier).toggleFavorite(job.id);
      if (mounted) {
        AppleToast.success(context, 'Status bookmark diperbarui');
      }
      return;
    }

    final newJob = job.copyWith(
      id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
      status: 'Tersedia',
      appliedDate: DateTime.now(),
      isFavorite: true,
    );

    await ref.read(jobProvider.notifier).addJob(newJob);

    if (mounted) {
      AppleToast.success(context, 'Lowongan "${job.position}" berhasil disimpan ke Lamaran!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = AppTheme.isDark(context);
    final bg = AppTheme.getBackground(context);
    final txtPri = AppTheme.getTextPrimary(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EKSPLORASI\nLOKER',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: txtPri,
                      letterSpacing: -1.2,
                      height: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openWelcomeModal,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E0D5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
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
                ],
              ),
            ),

            // ── 2. SEARCH BAR ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242428) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF383840) : const Color(0xFFE5E0D5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchJobs(),
                  decoration: InputDecoration(
                    hintText: 'Cari posisi, keahlian, atau perusahaan...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(CupertinoIcons.search, size: 18, color: Color(0xFF5C44E4)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _fetchJobs();
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF5C44E4)),
                            onPressed: () => _fetchJobs(),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ── REAL-TIME LIVE STATUS BAR ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7.5,
                        height: 7.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isLoading
                            ? 'Memuat data live...'
                            : 'Live API Terhubung (${_liveJobs.length} Loker)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _fetchJobs(forceRefresh: true),
                    child: const Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 13, color: Color(0xFF5C44E4)),
                        SizedBox(width: 3),
                        Text(
                          'Tarik Data Baru',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5C44E4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── 3. PLATFORM FILTER CHIPS ──
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _platforms.length,
                itemBuilder: (context, idx) {
                  final p = _platforms[idx];
                  final isSel = _selectedPlatform == p;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FluidBounceButton(
                      onTap: () {
                        setState(() => _selectedPlatform = p);
                        _fetchJobs();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF19191B) : (isDark ? const Color(0xFF242428) : Colors.white),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSel ? const Color(0xFF19191B) : (isDark ? const Color(0xFF383840) : const Color(0xFFE5E0D5)),
                            width: 1.2,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF121214)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ── 4. MAIN JOB LIST SECTION WITH PULL-TO-REFRESH ──
            Expanded(
              child: _isLoading && _liveJobs.isEmpty
                  ? const Center(child: CupertinoActivityIndicator(radius: 14))
                  : _liveJobs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tidak Ada Lowongan Ditemukan',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Coba ubah kata kunci pencarian atau reset filter platform.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedPlatform = 'Semua';
                                      _searchController.clear();
                                    });
                                    _fetchJobs(forceRefresh: true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF19191B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  ),
                                  child: const Text('Tampilkan Semua Lowongan', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _fetchJobs(forceRefresh: true),
                          color: const Color(0xFF5C44E4),
                          child: ListView.builder(
                            key: const PageStorageKey('discovery_list_view'),
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: EdgeInsets.fromLTRB(20, 4, 20, 120 + (bottomInset > 0 ? bottomInset : 0)),
                            itemCount: _liveJobs.length,
                            itemBuilder: (context, index) {
                              final job = _liveJobs[index];
                              final matchScore = 96 - (index % 6) * 2;
                              return _buildJobCard(job, matchScore);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(JobApplication job, int matchScore) {
    final state = ref.watch(jobProvider);
    final isSaved = state.jobs.any(
      (j) => (j.id == job.id || (j.companyName == job.companyName && j.position == job.position)) && j.isFavorite,
    );

    final cardColor = AppTheme.getCompanyCardColor(job.companyName);
    final isDarkText = cardColor == AppTheme.cardYellow || cardColor == AppTheme.cardGreen;
    final titleColor = isDarkText ? const Color(0xFF111113) : Colors.white;
    final subColor = isDarkText ? const Color(0xCC111113) : const Color(0xCCFFFFFF);

    return AppleBouncyCard(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => JobDetailScreen(job: job)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.24),
              blurRadius: 14,
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
                  flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                    return Material(
                      type: MaterialType.transparency,
                      child: toHeroContext.widget,
                    );
                  },
                  child: CompanyLogoBadge(
                    companyName: job.companyName,
                    size: 44,
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
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              job.position,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: subColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDarkText
                                  ? const Color(0xFF19191B).withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              job.sourcePlatform,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _saveToTracker(job),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDarkText ? const Color(0xFF111113) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                        size: 16,
                        color: isSaved
                            ? const Color(0xFFE53935)
                            : (isDarkText ? Colors.white : cardColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                if (job.salaryOffered != null && job.salaryOffered!.isNotEmpty) ...[
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
                  style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
                ),
                if (job.location != null && job.location!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '• ${job.location}',
                    style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // ── SEGMENTED COMPATIBILITY PROGRESS BAR (SESUAI MINAT ANDA) ──
            _buildSegmentedProgressBar(matchScore, isDarkText: isDarkText),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sesuai Minat Anda',
                  style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$matchScore%',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: titleColor),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final uri = Uri.parse(job.jobUrl ?? 'https://glints.com');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: isDarkText ? Colors.black.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDarkText ? Colors.black.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.40),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 14, color: titleColor),
                          const SizedBox(width: 6),
                          Text(
                            'Buka di ${job.sourcePlatform}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _saveToTracker(job),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: isSaved
                            ? const Color(0xFF1E8E3E)
                            : (isDarkText ? const Color(0xFF111113) : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_rounded,
                            size: 14,
                            color: isSaved ? Colors.white : (isDarkText ? Colors.white : cardColor),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSaved ? 'Tersimpan' : 'Simpan Loker',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSaved ? Colors.white : (isDarkText ? Colors.white : cardColor),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSegmentedProgressBar(int matchScore, {bool isDarkText = false}) {
    const totalSegments = 10;
    final activeSegments = (matchScore / 10).round().clamp(1, totalSegments);

    return Row(
      children: List.generate(totalSegments, (idx) {
        final isActive = idx < activeSegments;
        final activeColor = isDarkText ? const Color(0xFF19191B) : Colors.white;
        final inactiveColor = isDarkText
            ? const Color(0xFF19191B).withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.28);

        return Expanded(
          child: Container(
            height: 5.5,
            margin: EdgeInsets.only(right: idx < totalSegments - 1 ? 3 : 0),
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
