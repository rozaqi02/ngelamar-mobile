import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/job_search_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/company_logo_badge.dart';

/// Screen: Mesin Pencari Loker Agregator (Glints, JobStreet, & LinkedIn).
/// Fitur unggulan:
/// - Real-time keyword & city filter
/// - Platform selector (Glints, JobStreet, LinkedIn)
/// - 1-Tap Save to Tracker database lokal
/// - Buka langsung link lowongan asli di web
class JobDiscoveryScreen extends ConsumerStatefulWidget {
  const JobDiscoveryScreen({super.key});

  @override
  ConsumerState<JobDiscoveryScreen> createState() => _JobDiscoveryScreenState();
}

class _JobDiscoveryScreenState extends ConsumerState<JobDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedPlatform = 'Semua';
  String _selectedCity = 'Semua Kota';
  String _selectedWorkType = 'Semua';

  List<JobApplication> _searchResults = [];
  bool _isLoading = false;

  final List<String> _platforms = ['Semua', 'Glints', 'JobStreet'];
  final List<String> _cities = ['Semua Kota', 'Jakarta', 'Bandung', 'Remote / WFH'];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    setState(() => _isLoading = true);
    final results = await JobSearchService.searchJobs(
      query: _searchController.text,
      cityFilter: _selectedCity,
      platformFilter: _selectedPlatform,
      workTypeFilter: _selectedWorkType,
    );
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  void _saveToTracker(JobApplication job) async {
    HapticFeedback.mediumImpact();
    await ref.read(jobProvider.notifier).saveFromSearchEngine(job);
    if (mounted) {
      AppleToast.success(
        context,
        'Loker tersimpan ke Tracker!',
        subtitle: '${job.position} di ${job.companyName}',
      );
    }
  }

  void _openOriginalUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppTheme.warmBackground;
    const txtPri = AppTheme.textDark;

    final trackedJobs = ref.watch(jobProvider).jobs;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Header: Title + Subtitle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARI LOKER\nTERBARU',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: txtPri,
                        letterSpacing: -1.2,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Agregator lowongan dari Glints, JobStreet & LinkedIn Indonesia',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar Input
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCD8CE), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _performSearch(),
                    decoration: InputDecoration(
                      hintText: 'Cari posisi, skill (Flutter/Golang), atau PT...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1C1C1E)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // Filter Chips: Platform (Glints / JobStreet) & City
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    // Platform Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: _platforms.map((platform) {
                          final isSelected = _selectedPlatform == platform;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(platform),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF121214),
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFF1C1C1E),
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF1C1C1E) : const Color(0xFFDCD8CE),
                                ),
                              ),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedPlatform = platform);
                                _performSearch();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // City Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: _cities.map((city) {
                          final isSelected = _selectedCity == city;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: isSelected,
                              label: Text(city),
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFF5C44E4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF5C44E4) : const Color(0xFFE5E0D5),
                                ),
                              ),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCity = city);
                                _performSearch();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Results Counter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ditemukan ${_searchResults.length} Lowongan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF121214),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),

            // Search Results List
            if (_searchResults.isEmpty && !_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada lowongan yang cocok',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coba ganti kata kunci atau pilih opsi "Semua Kota".',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = _searchResults[index];
                      final isAlreadyTracked = trackedJobs.any(
                        (t) => t.companyName == job.companyName && t.position == job.position,
                      );
                      final cardBg = AppTheme.getCompanyCardColor(job.companyName);
                      final isDark = cardBg == AppTheme.cardYellow || cardBg == AppTheme.cardGreen;
                      final txtColor = isDark ? const Color(0xFF121214) : Colors.white;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Logo + Company Name + Platform Source Badge
                            Row(
                              children: [
                                CompanyLogoBadge(companyName: job.companyName, size: 38),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job.companyName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: txtColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        job.location ?? 'Indonesia',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: txtColor.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Platform Pill (Glints / JobStreet)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.90),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    job.sourcePlatform,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF121214),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Position Title
                            Text(
                              job.position,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: txtColor,
                                letterSpacing: -0.4,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Salary in IDR / formatted
                            Text(
                              job.salaryOffered ?? 'Gaji Kompetitif',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: txtColor,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Snippet Description / Requirements
                            Text(
                              job.jobDescription,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                                color: txtColor.withValues(alpha: 0.88),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 16),

                            // Actions Row: [Buka Web Asli ↗] + [+ Simpan ke Tracker]
                            Row(
                              children: [
                                // Direct Apply Web Link Button
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openOriginalUrl(job.jobUrl),
                                    icon: const Icon(Icons.arrow_outward_rounded, size: 14),
                                    label: const Text('Buka Web Asli'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? Colors.black87 : Colors.white,
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.black26
                                            : Colors.white.withValues(alpha: 0.4),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 1-Tap Save Button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isAlreadyTracked ? null : () => _saveToTracker(job),
                                    icon: Icon(
                                      isAlreadyTracked
                                          ? Icons.check_circle_rounded
                                          : Icons.bookmark_add_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      isAlreadyTracked ? 'Tersimpan' : '+ Catat Loker',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1C1C1E),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey.shade400,
                                      disabledForegroundColor: Colors.white70,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _searchResults.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
