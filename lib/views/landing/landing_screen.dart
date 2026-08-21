import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/job_provider.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/running_envelope_mascot.dart';
import '../main_navigation.dart';

/// Landing Screen / Entrance Screen with Interactive Onboarding Tutorial & Initial Data Setup.
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bobbingAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _bobbingAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OnboardingTutorialSheet(
        onComplete: (withSampleData, userName) async {
          Navigator.pop(ctx);
          final cleanName = userName.trim().isNotEmpty ? userName.trim() : 'Rozaqi';
          await ref.read(jobProvider.notifier).setUserName(cleanName);
          await PrefsService.setUserName(cleanName);

          if (withSampleData) {
            await ref.read(jobProvider.notifier).loadSampleJobs();
          } else {
            await ref.read(jobProvider.notifier).clearAllJobs();
          }
          await PrefsService.setOnboardingDone();

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainNavigation(),
              transitionsBuilder: (context, anim, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  child: child,
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ── TOP SCATTERED FLOATING SKILL / CATEGORY PILLS ──
            Positioned.fill(
              bottom: size.height * 0.40,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final dy = _bobbingAnim.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Hexagon Top-Left
                      Positioned(
                        top: 20 + dy * 0.4,
                        left: 20,
                        child: _buildHexagon(size: 38),
                      ),

                      // Circle Left
                      Positioned(
                        top: 80 - dy * 0.5,
                        left: 18,
                        child: _buildCircle(size: 32),
                      ),

                      // White Triangle
                      Positioned(
                        top: 60 + dy * 0.6,
                        left: size.width * 0.52,
                        child: _buildPlayTriangle(size: 40),
                      ),

                      // White Dot Pill
                      Positioned(
                        top: 40 - dy * 0.3,
                        left: size.width * 0.36,
                        child: _buildPillDot(),
                      ),

                      // White Dot Pill 2
                      Positioned(
                        top: 155 + dy * 0.4,
                        left: size.width * 0.28,
                        child: _buildPillDot(),
                      ),

                      // 1. UI/UX DESIGNER (Tech/Design - Top Center)
                      Positioned(
                        top: 8 + dy * 0.5,
                        left: size.width * 0.38,
                        child: _buildCategoryPill(
                          text: 'UI/UX DESIGNER',
                          bgColor: const Color(0xFFD8F2CA),
                          textColor: const Color(0xFF1A3311),
                          rotation: -18,
                        ),
                      ),

                      // 2. FINANCE & ACCOUNTING (Finance - Top Right)
                      Positioned(
                        top: 24 - dy * 0.4,
                        right: -10,
                        child: _buildCategoryPill(
                          text: 'FINANCE &\nACCOUNTING',
                          bgColor: const Color(0xFFDED2F9),
                          textColor: const Color(0xFF281E48),
                          rotation: 68,
                          isMultiLine: true,
                        ),
                      ),

                      // 3. PRODUCT MANAGER (Management - Upper Left)
                      Positioned(
                        top: 68 + dy * 0.7,
                        left: 56,
                        child: _buildCategoryPill(
                          text: 'PRODUCT\nMANAGER',
                          bgColor: const Color(0xFFFDE4C8),
                          textColor: const Color(0xFF38230F),
                          rotation: 12,
                          isMultiLine: true,
                        ),
                      ),

                      // 4. HR SPECIALIST (HR/Operations - Upper Right)
                      Positioned(
                        top: 100 - dy * 0.6,
                        right: -14,
                        child: _buildCategoryPill(
                          text: 'HR SPECIALIST',
                          bgColor: const Color(0xFFFDE4C8),
                          textColor: const Color(0xFF38230F),
                          rotation: -14,
                        ),
                      ),

                      // 5. DIGITAL MARKETING (Marketing - Left Middle)
                      Positioned(
                        top: 125 - dy * 0.5,
                        left: -6,
                        child: _buildCategoryPill(
                          text: 'DIGITAL\nMARKETING',
                          bgColor: const Color(0xFFDED2F9),
                          textColor: const Color(0xFF281E48),
                          rotation: -68,
                          isMultiLine: true,
                        ),
                      ),

                      // 6. DATA ANALYST (Tech - Center Middle)
                      Positioned(
                        top: 132 + dy * 0.5,
                        left: size.width * 0.36,
                        child: _buildCategoryPill(
                          text: 'DATA ANALYST',
                          bgColor: const Color(0xFFDED2F9),
                          textColor: const Color(0xFF281E48),
                          rotation: -14,
                        ),
                      ),

                      // 7. ADMIN OPERASIONAL (Operations - Right Middle)
                      Positioned(
                        top: 168 - dy * 0.5,
                        right: 18,
                        child: _buildCategoryPill(
                          text: 'ADMIN\nOPERASIONAL',
                          bgColor: const Color(0xFFD8F2CA),
                          textColor: const Color(0xFF1A3311),
                          rotation: 16,
                          isMultiLine: true,
                        ),
                      ),

                      // 8. FLUTTER DEV (Tech - Lower Left)
                      Positioned(
                        top: 196 + dy * 0.4,
                        left: 70,
                        child: _buildCategoryPill(
                          text: 'FLUTTER DEV',
                          bgColor: const Color(0xFFFDE4C8),
                          textColor: const Color(0xFF38230F),
                          rotation: 5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── CENTER: RUNNING ENVELOPE MASCOT (SURAT LAMARAN BERLARI) ──
            Positioned(
              top: size.height * 0.38,
              left: 0,
              right: 0,
              child: Center(
                child: RunningEnvelopeMascot(
                  width: math.min(size.width * 0.82, 270),
                  height: 185,
                ),
              ),
            ),

            // ── BOTTOM: INDONESIAN HEADLINE & CTA PILL BUTTON ──
            Positioned(
              left: 24,
              right: 24,
              bottom: bottomInset > 0 ? bottomInset + 18 : 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indonesian Headline (Matching Bold Typography)
                  const Text(
                    "Yuk, Raih Karir\nImpianmu!",
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.2,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle Indonesian
                  const Text(
                    "Kelola lamaran kerja, pantau tahapan interview, dan siapkan karirmu bersama Ngelamar.",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFA1A1AA),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lilac Capsule CTA Button ("Mulai Sekarang !" + Circle Arrow)
                  GestureDetector(
                    onTap: _onGetStarted,
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.fromLTRB(26, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDED2F9), // Soft Lilac / Lavender
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDED2F9).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Spacer(),
                          const Text(
                            "Mulai Sekarang !",
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF121214),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),

                          // Dark Circle with Right Arrow (→)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1C1C1E),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.arrow_right,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDGET HELPERS FOR FLOATING PILLS & ACCENTS ──

  Widget _buildCategoryPill({
    required String text,
    required Color bgColor,
    required Color textColor,
    required double rotation,
    bool isMultiLine = false,
  }) {
    return Transform.rotate(
      angle: rotation * (math.pi / 180),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMultiLine ? 16 : 14,
          vertical: isMultiLine ? 8 : 7,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMultiLine ? 10.5 : 11,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: 0.2,
            height: 1.15,
          ),
        ),
      ),
    );
  }

  Widget _buildHexagon({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );
  }

  Widget _buildCircle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPlayTriangle({required double size}) {
    return Transform.rotate(
      angle: 15 * (math.pi / 180),
      child: CustomPaint(
        size: Size(size, size * 0.86),
        painter: _TrianglePainter(),
      ),
    );
  }

  Widget _buildPillDot() {
    return Container(
      width: 24,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingTutorialSheet extends StatefulWidget {
  final Function(bool withSampleData, String userName) onComplete;

  const OnboardingTutorialSheet({super.key, required this.onComplete});

  @override
  State<OnboardingTutorialSheet> createState() => _OnboardingTutorialSheetState();
}

class _OnboardingTutorialSheetState extends State<OnboardingTutorialSheet> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController(text: 'Rozaqi');
  int _currentPage = 0;

  final Set<String> _selectedInterests = {
    'Flutter / Mobile Dev',
    'UI/UX & Product Design',
    'QA Automation / Tester',
  };

  final TextEditingController _customInterestController = TextEditingController();

  final Map<String, List<String>> _categorizedInterests = {
    '💻 Teknologi, IT & Software': [
      'Flutter / Mobile Dev',
      'Web & Frontend Dev',
      'Backend (Go/Node/Java)',
      'UI/UX & Product Design',
      'Data Analyst / AI',
      'QA Automation / Tester',
      'Cyber Security & DevOps',
    ],
    '📊 Bisnis, Produk & Manajemen': [
      'Product Manager',
      'Business Analyst',
      'Project Management',
      'Sales & Business Dev',
      'Operasional & Konsultan',
    ],
    '💰 Keuangan, Bank & Akuntansi': [
      'Finance & Accounting',
      'Tax Specialist',
      'Internal Auditor',
      'Banking Specialist',
    ],
    '📣 Pemasaran, Konten & Desain': [
      'Digital Marketing / SEO',
      'Content Creator / Copywriter',
      'Graphic Designer',
      'Social Media Specialist',
    ],
    '👥 SDM, Admin & Operasional': [
      'HR & Recruitment',
      'Admin & Operasional Kantor',
      'Customer Support',
      'Supply Chain & Logistik',
    ],
  };

  final List<String> _customInterests = [];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _customInterestController.dispose();
    super.dispose();
  }

  void _addCustomInterest() {
    final text = _customInterestController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        if (!_customInterests.contains(text)) {
          _customInterests.insert(0, text);
        }
        _selectedInterests.add(text);
        _customInterestController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const totalPages = 5;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppTheme.warmBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Indicator Dots
                Row(
                  children: List.generate(totalPages, (i) {
                    final isCurrent = _currentPage == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: isCurrent ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFF121214) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                if (_currentPage < totalPages - 1)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _pageController.animateToPage(
                        totalPages - 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text(
                      'Lewati',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),

          // PageView Slides
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [
                // SLIDE 1: PERSONALISASI NAMA
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 30 + bottomInset),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDED2F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 2),
                        ),
                        child: const Icon(CupertinoIcons.person_fill, size: 36, color: Color(0xFF121214)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Halo, Siapa Namamu?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF121214),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Masukkan namamu agar Ngelamar dapat mempersonalisasi eksplorasi karir dan portofoliomu:',
                        style: TextStyle(fontSize: 13, color: Color(0xFF555558), height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'Nama lengkap kamu...',
                          prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF121214)),
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: Color(0xFFDCD8CE), width: 1.2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: Color(0xFFDCD8CE), width: 1.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // SLIDE 2: TRACKER
                _buildSlideContent(
                  bottomInset: bottomInset,
                  icon: Icons.view_carousel_rounded,
                  color: const Color(0xFFDED2F9),
                  title: 'Lacak Lamaran Tanpa Stres',
                  desc: 'Pantau setiap proses dari tahap Dikirim, Tes, Interview HR, hingga Offering dalam satu dashboard kartu visual interaktif.',
                  tags: ['Progres 1-Klik', 'Pengingat Interview', 'Statistik Respon'],
                ),

                // SLIDE 3: AUTO-FILL & SCREENSHOT
                _buildSlideContent(
                  bottomInset: bottomInset,
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFFFFEAA7),
                  title: 'Auto-Isi Pintar & Bukti Loker',
                  desc: 'Cukup salin link lowongan dari LinkedIn, JobStreet, atau Glints untuk pengisian otomatis, dan lampirkan bukti foto screenshot loker.',
                  tags: ['Ekstrak Link Instan', 'Simpan Screenshot', 'Kontak HR'],
                ),

                // SLIDE 4: PILIH MINAT KARIR (MIN. 3)
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 40 + bottomInset),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE4C8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 2),
                        ),
                        child: const Icon(Icons.stars_rounded, size: 34, color: Color(0xFF121214)),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Pilih Minat Karirmu',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF121214),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pilih minimal 3 bidang pekerjaan yang Anda minati agar aplikasi dapat mengkurasi lowongan terbaik untuk Anda:',
                        style: TextStyle(fontSize: 13, color: Color(0xFF555558), height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Counter Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _selectedInterests.length >= 3
                              ? const Color(0xFFD8F2CA)
                              : const Color(0xFFFFEAA7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedInterests.length >= 3
                                ? const Color(0xFF81C784)
                                : const Color(0xFFFFD54F),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedInterests.length >= 3
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              size: 16,
                              color: _selectedInterests.length >= 3
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedInterests.length >= 3
                                  ? 'Dipilih: ${_selectedInterests.length} Minat (Siap Lanjut!)'
                                  : 'Dipilih: ${_selectedInterests.length} / min. 3 Minat',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _selectedInterests.length >= 3
                                    ? const Color(0xFF1B5E20)
                                    : const Color(0xFF121214),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Categorized Interest Groups with Modern Structured Layout
                      ..._categorizedInterests.entries.map((category) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E0D5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.key,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF121214),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: category.value.map((interest) {
                                  final isSelected = _selectedInterests.contains(interest);
                                  return FluidBounceButton(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedInterests.remove(interest);
                                        } else {
                                          _selectedInterests.add(interest);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF1C1C1E) : const Color(0xFFF6F4EE),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF1C1C1E) : const Color(0xFFE2DDD2),
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.12),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected) ...[
                                            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            interest,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                              color: isSelected ? Colors.white : const Color(0xFF222224),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }),

                      if (_customInterests.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E0D5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '✨ Minat Kustom Tambahan',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF121214),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _customInterests.map((interest) {
                                  final isSelected = _selectedInterests.contains(interest);
                                  return FluidBounceButton(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedInterests.remove(interest);
                                        } else {
                                          _selectedInterests.add(interest);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF1C1C1E) : const Color(0xFFF6F4EE),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF1C1C1E) : const Color(0xFFE2DDD2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected) ...[
                                            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            interest,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                              color: isSelected ? Colors.white : const Color(0xFF222224),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),

                      // Custom Interest Input Field
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customInterestController,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Tambah minat lain (misal: AI Engineer)...',
                                fillColor: Colors.white,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFDCD8CE)),
                                ),
                              ),
                              onSubmitted: (_) => _addCustomInterest(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addCustomInterest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5C44E4),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // SLIDE 5: PILIHAN MULAI
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 40 + bottomInset),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8F2CA),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 2),
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, size: 40, color: Color(0xFF121214)),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Siap Raih Karir Impianmu?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF121214),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pilih bagaimana Anda ingin memulai aplikasi ini:',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF555558)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      _buildChoiceCard(
                        title: 'Mulai dengan Data Contoh',
                        subtitle: 'Muat 6 contoh lamaran lengkap (BCA, Shopee, Tokopedia, dll) agar bisa langsung mencoba seluruh fitur.',
                        isPrimary: true,
                        badgeText: 'REKOMENDASI',
                        onTap: () async {
                          HapticFeedback.heavyImpact();
                          await PrefsService.setUserInterests(_selectedInterests.toList());
                          widget.onComplete(true, _nameController.text.trim());
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildChoiceCard(
                        title: 'Mulai dari Nol (Kosong)',
                        subtitle: 'Mulai dengan daftar lamaran bersih untuk mencatat lamaran Anda sendiri dari awal.',
                        isPrimary: false,
                        badgeText: null,
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await PrefsService.setUserInterests(_selectedInterests.toList());
                          widget.onComplete(false, _nameController.text.trim());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar (Safe for Android Navbar & Gesture Bar)
          if (_currentPage < totalPages - 1) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(24, 6, 24, bottomInset > 0 ? bottomInset + 14 : 24),
              child: FluidBounceButton(
                onTap: (_currentPage == 3 && _selectedInterests.length < 3)
                    ? null
                    : () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (_currentPage == 3 && _selectedInterests.length < 3)
                        ? Colors.grey.shade400
                        : const Color(0xFF121214),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: (_currentPage == 3 && _selectedInterests.length < 3)
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == 3 ? 'Lanjut (${_selectedInterests.length} Minat Terpilih)' : 'Lanjut',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlideContent({
    required double bottomInset,
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required List<String> tags,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 30 + bottomInset),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: 2),
            ),
            child: Icon(icon, size: 40, color: const Color(0xFF121214)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF121214),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(fontSize: 14, color: Color(0xFF555558), height: 1.45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCD8CE)),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF121214)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required bool isPrimary,
    required String? badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isPrimary ? const Color(0xFF1C1C1E) : const Color(0xFFDCD8CE),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isPrimary ? 0.12 : 0.04),
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isPrimary ? Colors.white : const Color(0xFF121214),
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                color: isPrimary ? Colors.white70 : const Color(0xFF555558),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
