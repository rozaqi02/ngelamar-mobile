import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/prefs_service.dart';
import '../../widgets/running_envelope_mascot.dart';
import '../main_navigation.dart';

/// Landing Screen / Entrance Screen.
/// Pixel-perfect recreation of the user-provided design reference:
/// - Dark background (#0D0D0E)
/// - Scattered floating rotated skill/category pill badges (Matcha, Peach, Lilac)
/// - Playful running envelope mascot (Surat Lamaran Berlari)
/// - Indonesian headline: "Yuk, Raih Karir\nImpianmu!"
/// - Soft Lilac CTA Button: "Mulai Sekarang !" with black circular arrow button
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
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

  void _onGetStarted() async {
    HapticFeedback.heavyImpact();
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

                      // 1. UI/UX DESIGNER (Matcha Green - Top Center)
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

                      // 2. IOS DEVELOPER (Soft Lilac - Top Right)
                      Positioned(
                        top: 24 - dy * 0.4,
                        right: -10,
                        child: _buildCategoryPill(
                          text: 'IOS DEVELOPER',
                          bgColor: const Color(0xFFDED2F9),
                          textColor: const Color(0xFF281E48),
                          rotation: 68,
                        ),
                      ),

                      // 3. ANDROID DEVELOPER (Peach - Upper Left)
                      Positioned(
                        top: 68 + dy * 0.7,
                        left: 56,
                        child: _buildCategoryPill(
                          text: 'ANDROID\nDEVELOPER',
                          bgColor: const Color(0xFFFDE4C8),
                          textColor: const Color(0xFF38230F),
                          rotation: 12,
                          isMultiLine: true,
                        ),
                      ),

                      // 4. HR MANAGER (Peach - Upper Right)
                      Positioned(
                        top: 100 - dy * 0.6,
                        right: -14,
                        child: _buildCategoryPill(
                          text: 'HR MANAGER',
                          bgColor: const Color(0xFFFDE4C8),
                          textColor: const Color(0xFF38230F),
                          rotation: -14,
                        ),
                      ),

                      // 5. WEB DESIGN (Lilac - Left Middle)
                      Positioned(
                        top: 125 - dy * 0.5,
                        left: -6,
                        child: _buildCategoryPill(
                          text: 'WEB DESIGN',
                          bgColor: const Color(0xFFDED2F9),
                          textColor: const Color(0xFF281E48),
                          rotation: -68,
                        ),
                      ),

                      // 6. GRAPHIC DESIGN (Lilac - Center Middle)
                      Positioned(
                        top: 132 + dy * 0.5,
                        left: size.width * 0.36,
                        child: _buildCategoryPill(
                          text: 'GRAPHIC DESIGN',
                          bgColor: const Color(0xFFDED2F9),
                          textColor: const Color(0xFF281E48),
                          rotation: -14,
                        ),
                      ),

                      // 7. MARKETING MANAGER (Matcha Green - Right Middle)
                      Positioned(
                        top: 168 - dy * 0.5,
                        right: 18,
                        child: _buildCategoryPill(
                          text: 'MARKETING\nMANAGER',
                          bgColor: const Color(0xFFD8F2CA),
                          textColor: const Color(0xFF1A3311),
                          rotation: 16,
                          isMultiLine: true,
                        ),
                      ),

                      // 8. IOS DEVELOPER (Peach - Lower Left)
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
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bobbingAnim.value * 0.8),
                    child: Center(
                      child: RunningEnvelopeMascot(
                        width: math.min(size.width * 0.82, 270),
                        height: 185,
                      ),
                    ),
                  );
                },
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
