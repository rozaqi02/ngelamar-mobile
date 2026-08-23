import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/analytics_service.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/welcome_screen_route.dart';
import 'discovery_welcome_screen.dart';

/// Screen 2: pintasan pencarian ke portal loker pihak ketiga.
/// Header style konsisten 100% dengan menu DAFTAR LAMARAN dan PERSIAPAN KARIR:
/// - Header: "EKSPLOR LOKER" besar tebal + Tombol (?) Info di kanan atas + Subtitle deskriptif
/// - Kata kunci diteruskan ke portal yang dipilih pengguna
/// - Category Filter Chips (Semua, Desainer UI/UX, Flutter Dev, Backend, dll.)
/// - 6 Kartu portal bergaya neo-modern dengan tujuan yang jelas.
class JobDiscoveryScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const JobDiscoveryScreen({super.key, this.embedded = false});

  @override
  ConsumerState<JobDiscoveryScreen> createState() => _JobDiscoveryScreenState();
}

class _JobDiscoveryScreenState extends ConsumerState<JobDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua bidang';
  Timer? _searchDebounce;

  final List<String> _categories = [
    'Semua bidang',
    'Desainer UI/UX',
    'Flutter Developer',
    'Backend Engineer',
    'Desainer Produk',
    'Data Analyst',
    'Digital Marketing',
    'Admin Operasional',
    'Fresh Graduate',
    'Remote / WFH',
  ];

  final List<Map<String, dynamic>> _portals = [
    {
      'name': 'LinkedIn Jobs',
      'watermark': 'L',
      'highlight': '10.000+',
      'highlightUnit': 'Lowongan',
      'roleTitle': 'Senior & Entry-Level Roles',
      'tagline': 'Jejaring Profesional Global',
      'bgColor': Color(0xFFC7EAA7), // Pastel Soft Green
      'portalColor': Color(0xFF0A66C2),
      'icon': Icons.business_center_rounded,
      'logoAsset': 'assets/portal_logos/linkedin.png',
      'logoUrl':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/LinkedIn_logo_initials.png/480px-LinkedIn_logo_initials.png',
      'partnerCount': '50+',
      'avatarColors': [
        Color(0xFF4A90E2),
        Color(0xFF50E3C2),
        Color(0xFFF5A623),
        Color(0xFFE94E77),
      ],
      'getUrl': (String key) {
        final q = Uri.encodeComponent(key.isEmpty ? 'Lowongan Kerja' : key);
        return 'https://www.linkedin.com/jobs/search/?keywords=$q&location=Indonesia';
      },
    },
    {
      'name': 'Glints',
      'watermark': 'G',
      'highlight': '8.500+',
      'highlightUnit': 'Lowongan',
      'roleTitle': 'Tech, Startup & Creative Roles',
      'tagline': 'Pusat Karir Startup Asia',
      'bgColor': Color(0xFFE2C8FF), // Pastel Soft Purple
      'portalColor': Color(0xFFEC272B),
      'icon': Icons.rocket_launch_rounded,
      'logoAsset': 'assets/portal_logos/glints.png',
      'logoUrl':
          'https://images.glints.com/unsafe/glints-dashboard.s3.amazonaws.com/favicon.png',
      'partnerCount': '40+',
      'avatarColors': [
        Color(0xFF9013FE),
        Color(0xFFBD10E0),
        Color(0xFF417505),
        Color(0xFFF8E71C),
      ],
      'getUrl': (String key) {
        final q = Uri.encodeComponent(key.isEmpty ? 'Lowongan Kerja' : key);
        return 'https://glints.com/id/opportunities/jobs/explore?keyword=$q&country=ID';
      },
    },
    {
      'name': 'JobStreet by SEEK',
      'watermark': 'J',
      'highlight': '25.000+',
      'highlightUnit': 'Lowongan',
      'roleTitle': 'Corporate, BUMN & SME Roles',
      'tagline': 'Semua Sektor Industri Terbesar',
      'bgColor': Color(0xFFFEF08A), // Pastel Soft Yellow
      'portalColor': Color(0xFF184178),
      'icon': Icons.work_rounded,
      'logoAsset': 'assets/portal_logos/jobstreet.png',
      'logoUrl':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/JobStreet_Logo_2022.svg/512px-JobStreet_Logo_2022.svg.png',
      'partnerCount': '100+',
      'avatarColors': [
        Color(0xFF184178),
        Color(0xFFE60278),
        Color(0xFF00B4D8),
        Color(0xFFFFB703),
      ],
      'getUrl': (String key) {
        final q = Uri.encodeComponent(
          (key.isEmpty ? 'Lowongan Kerja' : key).replaceAll(' ', '-'),
        );
        return 'https://www.jobstreet.co.id/id/job-search/$q-jobs';
      },
    },
    {
      'name': 'Kalibrr',
      'watermark': 'K',
      'highlight': '4.200+',
      'highlightUnit': 'Lowongan',
      'roleTitle': 'Enterprise & BUMN Hiring',
      'tagline': 'Perekrutan Berbasis Keahlian',
      'bgColor': Color(0xFFBAE6FD), // Pastel Soft Sky Blue
      'portalColor': Color(0xFF0284C7),
      'icon': Icons.account_balance_rounded,
      'logoAsset': 'assets/portal_logos/kalibrr.png',
      'logoUrl':
          'https://res.cloudinary.com/kalibrr-development/image/upload/v1/kalibrr-logo-favicon.png',
      'partnerCount': '35+',
      'avatarColors': [
        Color(0xFF0284C7),
        Color(0xFF38BDF8),
        Color(0xFF818CF8),
        Color(0xFFA78BFA),
      ],
      'getUrl': (String key) {
        final q = Uri.encodeComponent(key.isEmpty ? 'Lowongan Kerja' : key);
        return 'https://www.kalibrr.com/job-board/te/$q/1';
      },
    },
    {
      'name': 'KitaLulus',
      'watermark': 'K',
      'highlight': '12.000+',
      'highlightUnit': 'Lowongan',
      'roleTitle': 'Pencarian Loker',
      'tagline': 'Periksa detail lowongan sebelum melamar',
      'bgColor': Color(0xFFFECDD3), // Pastel Soft Coral Pink
      'portalColor': Color(0xFF00A5B5),
      'icon': Icons.verified_user_rounded,
      'logoAsset': 'assets/portal_logos/kitalulus.png',
      'logoUrl': 'https://kerja.kitalulus.com/favicon.ico',
      'partnerCount': '60+',
      'avatarColors': [
        Color(0xFF00A5B5),
        Color(0xFF2EC4B6),
        Color(0xFFFF9F1C),
        Color(0xFFE71D36),
      ],
      'getUrl': (String key) {
        final q = Uri.encodeComponent(key.isEmpty ? 'Lowongan Kerja' : key);
        return 'https://kerja.kitalulus.com/id/lowongan?q=$q';
      },
    },
    {
      'name': 'Indeed',
      'watermark': 'I',
      'highlight': '50.000+',
      'highlightUnit': 'Lowongan',
      'roleTitle': 'Agregator Karir Nasional',
      'tagline': 'Katalog Lowongan Terlengkap',
      'bgColor': Color(0xFFCCFBF1), // Pastel Soft Mint Teal
      'portalColor': Color(0xFF2164F3),
      'icon': Icons.travel_explore_rounded,
      'logoAsset': 'assets/portal_logos/indeed.png',
      'logoUrl':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Indeed_logo.png/480px-Indeed_logo.png',
      'partnerCount': '120+',
      'avatarColors': [
        Color(0xFF2164F3),
        Color(0xFF3B82F6),
        Color(0xFF10B981),
        Color(0xFF6366F1),
      ],
      'getUrl': (String key) {
        final q = Uri.encodeComponent(key.isEmpty ? 'Lowongan Kerja' : key);
        return 'https://id.indeed.com/jobs?q=$q&l=Indonesia';
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserDefault();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDefault() async {
    final interests = await PrefsService.getUserInterests();
    if (interests.isNotEmpty && mounted) {
      setState(() {
        _searchController.text = interests.first;
        _selectedCategory = '';
      });
    }
  }

  Future<void> _launchPortal(Map<String, dynamic> portal) async {
    final keyword = _searchController.text.trim().isEmpty
        ? (_selectedCategory == 'Semua bidang'
              ? 'Lowongan Kerja'
              : _selectedCategory)
        : _searchController.text.trim();

    final confirmed = await AppDialog.show<bool>(
      context: context,
      icon: CupertinoIcons.arrow_up_right,
      iconColor: portal['portalColor'] as Color,
      title: 'Buka ${portal['name']}?',
      content:
          'Anda akan diarahkan ke portal resmi ${portal['name']} untuk melihat lowongan dengan kata kunci “$keyword”.',
      secondaryLabel: 'Batal',
      primaryLabel: 'Buka Portal',
    );
    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    AnalyticsService.track(
      'portal_opened',
      properties: {'portal': portal['name']?.toString() ?? 'unknown'},
    );

    final url = portal['getUrl'](keyword) as String;
    try {
      final uri = Uri.parse(url);
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success && mounted) {
        await _showPortalError(portal['name'].toString(), url);
      } else if (mounted) {
        AppleToast.success(context, 'Membuka ${portal['name']}');
      }
    } catch (_) {
      if (mounted) await _showPortalError(portal['name'].toString(), url);
    }
  }

  Future<void> _showPortalError(String portalName, String url) async {
    final copy = await AppDialog.show<bool>(
      context: context,
      icon: Icons.link_off_rounded,
      iconColor: const Color(0xFFE0594F),
      title: '$portalName belum dapat dibuka',
      content:
          'Periksa koneksi internet atau salin tautannya untuk dibuka secara manual.',
      secondaryLabel: 'Tutup',
      primaryLabel: 'Salin tautan',
    );
    if (copy != true || !mounted) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) AppleToast.success(context, 'Tautan berhasil disalin');
  }

  void _openWelcomeModal() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      WelcomeScreenRoute(child: const DiscoveryWelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final gradientColors = isDark
        ? const [Color(0xFF0F1E14), Color(0xFF14241B), Color(0xFF121214)]
        : const [Color(0xFFD8F3DC), Color(0xFFEEF8EE), Color(0xFFF5EFE6)];

    final content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: SafeArea(
        top: !widget.embedded,
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── TOP HEADER (STYLE IDENTIK DENGAN DAFTAR LAMARAN & PERSIAPAN KARIR) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  widget.embedded ? 8 : 16,
                  20,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'CARI\nLOKERKU',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: txtPri,
                            letterSpacing: -1.2,
                            height: 1.0,
                          ),
                        ),
                        FluidBounceButton(
                          onTap: _openWelcomeModal,
                          semanticLabel: 'Buka panduan Cari Lokerku',
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
                              color: Color(0xFF1E8E3E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppSearchField(
                      controller: _searchController,
                      hintText: 'Contoh: Flutter, BUMN, remote, startup...',
                      onChanged: (value) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 250),
                          () {
                            if (!mounted) return;
                            final normalized = value.trim();
                            setState(() {
                              _selectedCategory =
                                  _categories.contains(normalized)
                                  ? normalized
                                  : '';
                            });
                          },
                        );
                      },
                      onClear: () {
                        _searchDebounce?.cancel();
                        setState(() => _selectedCategory = 'Semua bidang');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── QUICK KEYWORD CHIPS ──
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return FluidBounceButton(
                          semanticLabel: 'Gunakan kata kunci $cat',
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                              _searchController.text = cat == 'Semua bidang'
                                  ? ''
                                  : cat;
                              _searchController.selection =
                                  TextSelection.collapsed(
                                    offset: _searchController.text.length,
                                  );
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1E8E3E)
                                  : (isDark
                                        ? const Color(0xFF203027)
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1E8E3E)
                                    : (isDark
                                          ? const Color(0xFF31523A)
                                          : const Color(0xFFBFDCC6)),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1E8E3E,
                                  ).withValues(alpha: isSelected ? 0.22 : 0.04),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                              ? const Color(0xFFCFE9D5)
                                              : const Color(0xFF20442A)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── SECTION HEADER: "PILIHAN PORTAL LOKER" ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilihan Portal Loker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: txtPri,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '6 Portal Pilihan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── BIG COLORFUL NEO-MODERN CARDS (100% PERSIS MOCKUP) ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, idx) {
                  final portal = _portals[idx];
                  final Color cardBg = isDark
                      ? const Color(0xFF1E1E24)
                      : (portal['bgColor'] as Color);
                  final Color portalColor = portal['portalColor'] as Color;
                  final String name = portal['name'] as String;
                  final String watermark = portal['watermark'] as String;
                  final String roleTitle = portal['roleTitle'] as String;
                  final String tagline = portal['tagline'] as String;
                  final IconData icon = portal['icon'] as IconData;
                  final String logoAsset = portal['logoAsset'] as String;
                  final String logoUrl = portal['logoUrl'] as String;

                  return AppleBouncyCard(
                    onTap: () => _launchPortal(portal),
                    semanticLabel: 'Buka ${portal['name']} di aplikasi browser',
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF383842)
                              : Colors.transparent,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.05,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // ── GIANT FAINT WATERMARK LETTER ──
                          Positioned(
                            right: -12,
                            bottom: -20,
                            child: Text(
                              watermark,
                              style: TextStyle(
                                fontSize: 170,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.28),
                                letterSpacing: -10,
                              ),
                            ),
                          ),

                          // ── CARD FOREGROUND CONTENT ──
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: identitas portal. Aksi eksternal hanya
                                // ditampilkan sekali pada CTA di bagian bawah.
                                Row(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF282830)
                                                : Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.08,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              logoAsset,
                                              width: 30,
                                              height: 30,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, _, _) =>
                                                  Image.network(
                                                    logoUrl,
                                                    width: 30,
                                                    height: 30,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, _, _) =>
                                                        Icon(
                                                          icon,
                                                          size: 22,
                                                          color: portalColor,
                                                        ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF121214),
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // Honest portal destination label (not a live job count).
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      'Cari cepat',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF121214),
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'di portal resmi',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFFA0A0A8)
                                            : const Color(0xFF4A5568),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                // Role Title & Tagline
                                Text(
                                  _searchController.text.trim().isNotEmpty
                                      ? 'Mencari "${_searchController.text.trim()}" di $name'
                                      : '$roleTitle • $tagline',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? const Color(0xFFE5E5E8)
                                        : const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 22),

                                // Bottom Row: external destination + action button.
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Left: explicit external navigation label.
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tujuan',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? const Color(0xFFA0A0A8)
                                                : const Color(0xFF4A5568),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: isDark ? 0.10 : 0.78,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF383842)
                                                  : Colors.white.withValues(
                                                      alpha: 0.9,
                                                    ),
                                            ),
                                          ),
                                          child: Text(
                                            'Situs eksternal',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Right: Solid Black Circle Action Button ↗
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF5C44E4)
                                            : const Color(0xFF121214),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          CupertinoIcons.arrow_up_right,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: _portals.length),
              ),
            ),
          ],
        ),
      ),
    );
    return widget.embedded ? content : Scaffold(body: content);
  }
}
