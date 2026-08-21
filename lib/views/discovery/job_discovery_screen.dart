import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_toast.dart';
import 'discovery_welcome_screen.dart';

/// Screen 2: Eksplor Loker.
/// Header style konsisten 100% dengan menu DAFTAR LAMARAN dan PERSIAPAN KARIR:
/// - Header: "EKSPLOR LOKER" besar tebal + Tombol (?) Info di kanan atas + Subtitle deskriptif
/// - Single Search Box yang bersih & elegan tanpa duplikasi
/// - Category Filter Chips (Semua, Desainer UI/UX, Flutter Dev, Backend, dll.)
/// - 6 Kartu Portal bergaya neo-modern pastel dengan watermark huruf raksasa,
///   avatar stack pelamar (Applied), dan tombol aksi bulat hitam ↗.
class JobDiscoveryScreen extends ConsumerStatefulWidget {
  const JobDiscoveryScreen({super.key});

  @override
  ConsumerState<JobDiscoveryScreen> createState() => _JobDiscoveryScreenState();
}

class _JobDiscoveryScreenState extends ConsumerState<JobDiscoveryScreen> {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
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
      'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/LinkedIn_logo_initials.png/480px-LinkedIn_logo_initials.png',
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
      'logoUrl': 'https://images.glints.com/unsafe/glints-dashboard.s3.amazonaws.com/favicon.png',
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
      'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/JobStreet_Logo_2022.svg/512px-JobStreet_Logo_2022.svg.png',
      'partnerCount': '100+',
      'avatarColors': [
        Color(0xFF184178),
        Color(0xFFE60278),
        Color(0xFF00B4D8),
        Color(0xFFFFB703),
      ],
      'getUrl': (String key) {
        final q = Uri.encodeComponent((key.isEmpty ? 'Lowongan Kerja' : key).replaceAll(' ', '-'));
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
      'logoUrl': 'https://res.cloudinary.com/kalibrr-development/image/upload/v1/kalibrr-logo-favicon.png',
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
      'roleTitle': 'Loker Aman Bebas Biaya',
      'tagline': '100% Terverifikasi & Anti Penipuan',
      'bgColor': Color(0xFFFECDD3), // Pastel Soft Coral Pink
      'portalColor': Color(0xFF00A5B5),
      'icon': Icons.verified_user_rounded,
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
      'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Indeed_logo.png/480px-Indeed_logo.png',
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDefault() async {
    final interests = await PrefsService.getUserInterests();
    if (interests.isNotEmpty && mounted) {
      setState(() {
        _searchController.text = interests.first;
      });
    }
  }

  void _launchPortal(Map<String, dynamic> portal) async {
    HapticFeedback.heavyImpact();
    final keyword = _searchController.text.trim().isEmpty
        ? (_selectedCategory == 'Semua' ? 'Lowongan Kerja' : _selectedCategory)
        : _searchController.text.trim();

    final url = portal['getUrl'](keyword) as String;
    try {
      final uri = Uri.parse(url);
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success && mounted) {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          AppleToast.info(context, 'Tautan ${portal['name']} disalin ke clipboard');
        }
      } else if (mounted) {
        AppleToast.success(context, 'Membuka ${portal['name']}');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        AppleToast.info(context, 'Tautan ${portal['name']} disalin ke clipboard');
      }
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

  Widget _buildAvatarStack(List<Color> avatarColors, String countText) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 28,
          child: Stack(
            children: [
              for (int i = 0; i < avatarColors.length; i++)
                Positioned(
                  left: i * 16.0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: avatarColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1.2),
          ),
          child: Text(
            countText,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF121214),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final gradientColors = isDark
        ? const [Color(0xFF0F1E14), Color(0xFF14241B), Color(0xFF121214)]
        : const [Color(0xFFD8F3DC), Color(0xFFEEF8EE), Color(0xFFF5EFE6)];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── TOP HEADER (STYLE IDENTIK DENGAN DAFTAR LAMARAN & PERSIAPAN KARIR) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'EKSPLOR\nLOKER',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF121214),
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
                    const SizedBox(height: 6),
                    Text(
                      'Pencarian kata kunci lowongan kerja di 6 portal resmi terpercaya',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── SINGLE SEARCH BAR (BERSIH & KONSISTEN TANPA EFEK DOUBLE BOX) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Ketik kata kunci posisi atau keahlian...',
                  placeholderStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF121214),
                  ),
                  backgroundColor: isDark ? const Color(0xFF242428) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onChanged: (_) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), () {
                      if (mounted) setState(() {});
                    });
                  },
                ),
              ),
            ),

            // ── CATEGORY FILTER CHIPS ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = _categories[idx];
                      final isSelected = _selectedCategory == cat;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategory = cat;
                            if (cat != 'Semua') {
                              _searchController.text = cat;
                            } else {
                              _searchController.clear();
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF19191B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF19191B) : const Color(0xFFE5E0D5),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isSelected ? 0.10 : 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF121214),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── SECTION HEADER: "PILIHAN PORTAL LOKER" ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilihan Portal Loker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF121214),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '6 Portal Terpercaya',
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
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final portal = _portals[idx];
                    final Color cardBg = portal['bgColor'] as Color;
                    final Color portalColor = portal['portalColor'] as Color;
                    final String name = portal['name'] as String;
                    final String watermark = portal['watermark'] as String;
                    final String highlight = portal['highlight'] as String;
                    final String highlightUnit = portal['highlightUnit'] as String;
                    final String roleTitle = portal['roleTitle'] as String;
                    final String tagline = portal['tagline'] as String;
                    final IconData icon = portal['icon'] as IconData;
                    final String partnerCount = portal['partnerCount'] as String;
                    final List<Color> avatarColors = portal['avatarColors'] as List<Color>;

                    return GestureDetector(
                      onTap: () => _launchPortal(portal),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
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
                                  color: Colors.white.withValues(alpha: 0.28),
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
                                  // Top Row: Logo Badge + Name + 3-Dots Action
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.08),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: Image.network(
                                                (portal['logoUrl'] as String?) ?? '',
                                                width: 30,
                                                height: 30,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) => Center(
                                                  child: Icon(icon, size: 20, color: portalColor),
                                                ),
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: Icon(icon, size: 20, color: portalColor),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF121214),
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            CupertinoIcons.ellipsis_vertical,
                                            size: 16,
                                            color: Color(0xFF121214),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 18),

                                  // Highlight Stat Row (e.g. 10.000+ Lowongan)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        highlight,
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF121214),
                                          letterSpacing: -1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        highlightUnit,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4A5568),
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 22),

                                  // Bottom Row: Applied Avatar Stack + Black Circle Action Button ↗
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Left: Applied Avatar Stack (Persis Mockup)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Applied',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF4A5568),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildAvatarStack(avatarColors, partnerCount),
                                        ],
                                      ),

                                      // Right: Solid Black Circle Action Button ↗
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF121214),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
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
                  },
                  childCount: _portals.length,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
