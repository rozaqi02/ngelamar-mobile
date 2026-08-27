import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/job_provider.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/company_logo_badge.dart';
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
          try {
            final cleanName = userName.trim();
            await ref.read(jobProvider.notifier).setUserName(cleanName);
            await PrefsService.setUserName(cleanName);

            final dataPrepared = withSampleData
                ? await ref.read(jobProvider.notifier).loadSampleJobs()
                : await ref.read(jobProvider.notifier).clearAllJobs();
            if (!dataPrepared) {
              throw StateError('Data awal belum dapat disiapkan.');
            }
            await PrefsService.setInitialDataSeeded(true);
            await PrefsService.setOnboardingDone(true);
          } catch (e) {
            debugPrint('Error preparing initial data: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Data awal belum dapat disiapkan. Silakan coba lagi.',
                  ),
                ),
              );
            }
            return;
          }

          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainNavigation(),
              transitionsBuilder: (context, anim, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  child: child,
                );
              },
            ),
            (route) => false,
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
            // Restore the expressive first-install career collage.
            Positioned.fill(
              bottom: size.height * 0.40,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  final dy = _bobbingAnim.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 20 + dy * .4,
                        left: 20,
                        child: _buildAccent(
                          size: const Size(38, 38),
                          radius: 8,
                        ),
                      ),
                      Positioned(
                        top: 80 - dy * .5,
                        left: 18,
                        child: _buildAccent(
                          size: const Size(32, 32),
                          circle: true,
                        ),
                      ),
                      Positioned(
                        top: 40 - dy * .3,
                        left: size.width * .36,
                        child: _buildAccent(
                          size: const Size(24, 10),
                          radius: 10,
                        ),
                      ),
                      Positioned(
                        top: 155 + dy * .4,
                        left: size.width * .28,
                        child: _buildAccent(
                          size: const Size(24, 10),
                          radius: 10,
                        ),
                      ),
                      Positioned(
                        top: 8 + dy * .5,
                        left: size.width * .38,
                        child: _buildCategoryPill(
                          text: 'UI/UX DESIGNER',
                          bgColor: const Color(0xFFD8F2CA),
                          textColor: const Color(0xFF1A3311),
                          rotation: -18,
                        ),
                      ),
                      Positioned(
                        top: 24 - dy * .4,
                        right: 8,
                        child: _buildCategoryPill(
                          text: 'FINANCE &\nACCOUNTING',
                          bgColor: const Color(0xFFDED2F9),
                          textColor: const Color(0xFF281E48),
                          rotation: 18,
                          isMultiLine: true,
                        ),
                      ),
                      Positioned(
                        top: 68 + dy * .7,
                        left: 56,
                        child: _buildCategoryPill(
                          text: 'PRODUCT\nMANAGER',
                          bgColor: const Color(0xFFFDE4C8),
                          textColor: const Color(0xFF38230F),
                          rotation: 12,
                          isMultiLine: true,
                        ),
                      ),
                      Positioned(
                        top: 100 - dy * .6,
                        right: 4,
                        child: _buildCategoryPill(
                          text: 'HR SPECIALIST',
                          bgColor: const Color(0xFFFDE4C8),
                          textColor: const Color(0xFF38230F),
                          rotation: -14,
                        ),
                      ),
                      Positioned(
                        top: 125 - dy * .5,
                        left: 6,
                        child: _buildCategoryPill(
                          text: 'DIGITAL\nMARKETING',
                          bgColor: const Color(0xFFDED2F9),
                          textColor: const Color(0xFF281E48),
                          rotation: -16,
                          isMultiLine: true,
                        ),
                      ),
                      Positioned(
                        top: 132 + dy * .5,
                        left: size.width * .36,
                        child: _buildCategoryPill(
                          text: 'DATA ANALYST',
                          bgColor: const Color(0xFFDED2F9),
                          textColor: const Color(0xFF281E48),
                          rotation: -14,
                        ),
                      ),
                      Positioned(
                        top: 168 - dy * .5,
                        right: 18,
                        child: _buildCategoryPill(
                          text: 'ADMIN\nOPERASIONAL',
                          bgColor: const Color(0xFFD8F2CA),
                          textColor: const Color(0xFF1A3311),
                          rotation: 16,
                          isMultiLine: true,
                        ),
                      ),
                      Positioned(
                        top: 196 + dy * .4,
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
                  FluidBounceButton(
                    onTap: _onGetStarted,
                    semanticLabel: 'Mulai onboarding',
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.fromLTRB(26, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDED2F9), // Soft Lilac / Lavender
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFDED2F9,
                            ).withValues(alpha: 0.35),
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
                            'Mulai Sekarang!',
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

  Widget _buildAccent({
    required Size size,
    double radius = 0,
    bool circle = false,
  }) => Container(
    width: size.width,
    height: size.height,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(radius),
    ),
  );
}

class OnboardingTutorialSheet extends StatefulWidget {
  final Function(bool withSampleData, String userName) onComplete;

  const OnboardingTutorialSheet({super.key, required this.onComplete});

  @override
  State<OnboardingTutorialSheet> createState() =>
      _OnboardingTutorialSheetState();
}

class _OnboardingTutorialSheetState extends State<OnboardingTutorialSheet> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  final Set<String> _selectedInterests = {};

  final TextEditingController _customInterestController =
      TextEditingController();

  final Map<String, List<String>> _categorizedInterests = {
    'Teknologi & Software': [
      'Flutter / Mobile Dev',
      'Web & Frontend Dev',
      'Backend (Go/Node/Java)',
      'UI/UX & Product Design',
      'Data Analyst / AI',
      'QA Automation / Tester',
      'Cyber Security & DevOps',
    ],
    'Bisnis & Manajemen': [
      'Product Manager',
      'Business Analyst',
      'Project Management',
      'Sales & Business Dev',
      'Operasional & Konsultan',
    ],
    'Keuangan & Akuntansi': [
      'Finance & Accounting',
      'Tax Specialist',
      'Internal Auditor',
      'Banking Specialist',
    ],
    'Pemasaran & Kreatif': [
      'Digital Marketing / SEO',
      'Content Creator / Copywriter',
      'Graphic Designer',
      'Social Media Specialist',
    ],
    'SDM & Operasional': [
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
    if (text.isNotEmpty && text.length <= 32) {
      setState(() {
        if (!_customInterests.contains(text)) {
          _customInterests.insert(0, text);
        }
        _selectedInterests.add(text);
        _customInterestController.clear();
      });
    }
  }

  Color _interestColor(String interest) {
    const colors = [
      Color(0xFF5C44E4),
      Color(0xFF1E8E3E),
      Color(0xFF2878D0),
      Color(0xFFD3543C),
      Color(0xFFC56A08),
      Color(0xFF007F86),
      Color(0xFF9B3FAE),
    ];
    final hash = interest.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return colors[hash % colors.length];
  }

  Widget _pageMotion(int index, Widget child) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    return AnimatedBuilder(
      animation: _pageController,
      child: child,
      builder: (context, child) {
        final page = _pageController.hasClients
            ? (_pageController.page ?? _currentPage.toDouble())
            : _currentPage.toDouble();
        final delta = (page - index).clamp(-1.0, 1.0);
        final distance = delta.abs();
        return Transform.translate(
          offset: Offset(-delta * 18, distance * 5),
          child: Transform.scale(
            scale: 1 - (distance * 0.025),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const totalPages = 5;
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom > media.padding.bottom
        ? media.viewInsets.bottom
        : media.padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      clipBehavior: Clip.antiAlias,
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
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: _currentPage > 0
                      ? IconButton(
                          tooltip: 'Kembali ke langkah sebelumnya',
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 340),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                // Page Indicator Dots
                Expanded(
                  child: Semantics(
                    label: 'Langkah ${_currentPage + 1} dari $totalPages',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalPages, (i) {
                        final isCurrent = _currentPage == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isCurrent ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF121214)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: _currentPage < totalPages - 1
                      ? TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            HapticFeedback.selectionClick();
                            _pageController.animateToPage(
                              totalPages - 1,
                              duration: const Duration(milliseconds: 520),
                              curve: Curves.easeInOutCubicEmphasized,
                            );
                          },
                          child: const Text(
                            'Lewati',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // PageView Slides
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: _currentPage == 3 && _selectedInterests.length < 3
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(parent: PageScrollPhysics()),
              onPageChanged: (idx) {
                HapticFeedback.selectionClick();
                setState(() => _currentPage = idx);
              },
              children: [
                // SLIDE 1: PERSONALISASI NAMA
                _pageMotion(
                  0,
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
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            size: 36,
                            color: Color(0xFF121214),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Halo, Siapa Namamu?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF121214),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Nama ini dipakai untuk mempersonalisasi pengalamanmu.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555558),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nama lengkap kamu...',
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: Color(0xFF121214),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFFDCD8CE),
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFFDCD8CE),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // SLIDE 2: TRACKER
                _pageMotion(
                  1,
                  _buildSlideContent(
                    bottomInset: bottomInset,
                    icon: Icons.view_carousel_rounded,
                    color: const Color(0xFFDED2F9),
                    title: 'Lacak Lamaran Tanpa Stres',
                    desc:
                        'Pantau Dikirim, Tes, Interview, hingga Offering dalam satu tracker.',
                    tags: ['Progres 1-Klik', 'Pengingat Interview'],
                  ),
                ),

                // SLIDE 3: AUTO-FILL & SCREENSHOT
                _pageMotion(
                  2,
                  _buildSlideContent(
                    bottomInset: bottomInset,
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFFEAA7),
                    title: 'Auto-Isi Pintar & Bukti Loker',
                    desc:
                        'Tempel link lowongan, isi form otomatis, lalu simpan screenshot sebagai bukti.',
                    tags: ['Ekstrak Link Instan', 'Simpan Screenshot'],
                  ),
                ),

                // SLIDE 4: PILIH MINAT KARIR (MIN. 3)
                _pageMotion(
                  3,
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
                          child: const Icon(
                            Icons.stars_rounded,
                            size: 34,
                            color: Color(0xFF121214),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Pilih Minat Karirmu',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF121214),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pilih minimal 3 bidang yang ingin kamu kejar.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555558),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Counter Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
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
                        const SizedBox(height: 10),
                        FluidBounceButton(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedInterests.addAll([
                                'Flutter Developer',
                                'UI/UX Designer',
                                'Product Manager',
                              ]);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF5C44E4,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF5C44E4,
                                ).withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: Color(0xFF5C44E4),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Pilih Cepat 3 Rekomendasi Terpopuler',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5C44E4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Categorized Interest Groups with Modern Structured Layout
                        ..._categorizedInterests.entries.map((category) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE5E0D5),
                              ),
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
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF121214),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: category.value.map((interest) {
                                    final isSelected = _selectedInterests
                                        .contains(interest);
                                    return FluidBounceButton(
                                      semanticLabel: interest,
                                      selected: isSelected,
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
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? _interestColor(interest)
                                              : const Color(0xFFF6F4EE),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? _interestColor(interest)
                                                : const Color(0xFFE2DDD2),
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Text(
                                          interest,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF222224),
                                          ),
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
                              border: Border.all(
                                color: const Color(0xFFE5E0D5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Minat tambahan',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF121214),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _customInterests.map((interest) {
                                    final isSelected = _selectedInterests
                                        .contains(interest);
                                    return FluidBounceButton(
                                      semanticLabel: interest,
                                      selected: isSelected,
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
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? _interestColor(interest)
                                              : const Color(0xFFF6F4EE),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? _interestColor(interest)
                                                : const Color(0xFFE2DDD2),
                                          ),
                                        ),
                                        child: Text(
                                          interest,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF222224),
                                          ),
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
                                maxLength: 32,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Minat lain, misalnya AI Engineer',
                                  counterText: '',
                                  fillColor: Colors.white,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFDCD8CE),
                                    ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Tambah',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // SLIDE 5: PILIHAN MULAI
                _pageMotion(
                  4,
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
                          child: const Icon(
                            Icons.rocket_launch_rounded,
                            size: 40,
                            color: Color(0xFF121214),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Siap Raih Karir Impianmu?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF121214),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pilih cara paling nyaman untuk mulai.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF555558),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        _buildChoiceCard(
                          title: 'Mulai dengan Data Contoh',
                          subtitle:
                              'Muat 6 lamaran dummy terkunci untuk mengenal fitur tracker.',
                          isPrimary: true,
                          badgeText: 'REKOMENDASI',
                          onTap: () => _handleSampleDataSelection(),
                        ),
                        const SizedBox(height: 12),
                        _buildChoiceCard(
                          title: 'Mulai dari Nol (Kosong)',
                          subtitle:
                              'Mulai dengan daftar lamaran bersih untuk mencatat lamaran Anda sendiri dari awal.',
                          isPrimary: false,
                          badgeText: null,
                          onTap: () => _finish(false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar (Safe for Android Navbar & Gesture Bar)
          if (_currentPage < totalPages - 1) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                6,
                24,
                bottomInset > 0 ? bottomInset + 14 : 24,
              ),
              child: FluidBounceButton(
                semanticLabel: _currentPage == 3
                    ? 'Lanjut dengan ${_selectedInterests.length} minat'
                    : 'Lanjut ke langkah berikutnya',
                onTap: (_currentPage == 3 && _selectedInterests.length < 3)
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 340),
                          curve: Curves.easeOutCubic,
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
                    boxShadow:
                        (_currentPage == 3 && _selectedInterests.length < 3)
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
                        _currentPage == 3
                            ? 'Lanjut (${_selectedInterests.length} Minat Terpilih)'
                            : 'Lanjut',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
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

  void _finish(bool withSampleData) async {
    HapticFeedback.heavyImpact();
    await PrefsService.setUserInterests(_selectedInterests.toList());
    widget.onComplete(withSampleData, _nameController.text.trim());
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: const Color(0xFF121214)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF121214),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555558),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCD8CE)),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF121214),
                  ),
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
    final iconData = isPrimary
        ? Icons.auto_stories_rounded
        : Icons.edit_note_rounded;
    final iconBg = isPrimary
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFFF0EBE1);
    final iconColor = isPrimary
        ? const Color(0xFFFFD54F)
        : const Color(0xFF5C44E4);

    return FluidBounceButton(
      onTap: onTap,
      scaleFactor: 0.985,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFDCD8CE),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
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
                            fontWeight: FontWeight.w700,
                            color: isPrimary
                                ? Colors.white
                                : const Color(0xFF121214),
                          ),
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF121214),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isPrimary
                          ? Colors.white70
                          : const Color(0xFF555558),
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

  void _handleSampleDataSelection() {
    HapticFeedback.mediumImpact();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Modal Rincian 6 Data Contoh
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx1) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.fromLTRB(
          22,
          16,
          22,
          bottomInset > 0 ? bottomInset + 14 : 22,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rincian 6 Data Contoh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF121214),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Masuk ke kategori Contoh. Status dikunci agar datanya tetap menjadi panduan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF555558)),
            ),
            const SizedBox(height: 14),

            // List of 6 Sample Jobs
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSamplePreviewItem(
                    company: 'Nusa Tech',
                    role: 'Flutter Dev',
                    status: 'Interview HR',
                    salary: 'Rp 8–11 jt / bln',
                    statusColor: const Color(0xFF7257D9),
                  ),
                  _buildSamplePreviewItem(
                    company: 'Karsa Labs',
                    role: 'UI Designer',
                    status: 'Offering',
                    salary: 'Rp 7–10 jt / bln',
                    statusColor: const Color(0xFF2E7D32),
                  ),
                  _buildSamplePreviewItem(
                    company: 'Bumi Data',
                    role: 'Data Analis',
                    status: 'Tes / Psikotes',
                    salary: 'Rp 7–9 jt / bln',
                    statusColor: const Color(0xFFE65100),
                  ),
                  _buildSamplePreviewItem(
                    company: 'Aruna Mart',
                    role: 'QA Engineer',
                    status: 'Dikirim',
                    salary: 'Rp 6–9 jt / bln',
                    statusColor: const Color(0xFF1565C0),
                  ),
                  _buildSamplePreviewItem(
                    company: 'Sora Bank',
                    role: 'HR Officer',
                    status: 'Interview User',
                    salary: 'Rp 6–8 jt / bln',
                    statusColor: const Color(0xFF6A1B9A),
                  ),
                  _buildSamplePreviewItem(
                    company: 'Tera Media',
                    role: 'Copywriter',
                    status: 'Dikirim',
                    salary: 'Rp 5–7 jt / bln',
                    statusColor: const Color(0xFF1565C0),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tombol Muat 6 Data Contoh
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _finish(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19191B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Gunakan 6 Data Contoh',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Opsi Mulai dari Nol (Kosong)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  _finish(false);
                },
                child: const Text(
                  'Tidak Perlu, Mulai dari Nol (Kosong)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF707074),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSamplePreviewItem({
    required String company,
    required String role,
    required String status,
    required String salary,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E0D5)),
      ),
      child: Row(
        children: [
          CompanyLogoBadge(companyName: company, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF121214),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$role • $salary',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF555558),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
