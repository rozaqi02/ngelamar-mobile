import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget visual tumpukan amplop otentik Ngelamar dengan animasi masuk staggered & floating wave.
class AnimatedEnvelopeStackGraphic extends StatefulWidget {
  final double width;
  final double height;
  final Color accentColor;
  final String topBadgeText;
  final String heroBadgeText;

  const AnimatedEnvelopeStackGraphic({
    super.key,
    this.width = 320,
    this.height = 280,
    this.accentColor = const Color(0xFF6344F5),
    this.topBadgeText = 'Lowongan Resmi',
    this.heroBadgeText = 'Lamaran Terkirim',
  });

  @override
  State<AnimatedEnvelopeStackGraphic> createState() =>
      _AnimatedEnvelopeStackGraphicState();
}

class _AnimatedEnvelopeStackGraphicState
    extends State<AnimatedEnvelopeStackGraphic>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _floatingController;

  late Animation<double> _backEnvelopeEntrance;
  late Animation<double> _midEnvelopeEntrance;
  late Animation<double> _frontEnvelopeEntrance;
  late Animation<double> _glowEntrance;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    // ── 1. ENTRANCE STAGGERED SPRING ANIMATION ──
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _glowEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _backEnvelopeEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
    );

    _midEnvelopeEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOutBack),
    );

    _frontEnvelopeEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
    );

    // ── 2. CONTINUOUS FLOATING ANIMATION ──
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _floatingController]),
        builder: (context, child) {
          final dy = _floatAnim.value;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // ── AMBIENT RADIAL GLOW ──
              ScaleTransition(
                scale: _glowEntrance,
                child: Container(
                  width: widget.width * 0.95,
                  height: widget.height * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accentColor.withValues(alpha: 0.38),
                        widget.accentColor.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // ── FLOATING ACCENT PARTICLES ──
              Positioned(
                top: 20 + dy * 0.5,
                left: 20,
                child: _buildSparkle(size: 14, color: const Color(0xFFFFD54F)),
              ),
              Positioned(
                top: 40 - dy * 0.4,
                right: 25,
                child: _buildSparkle(size: 18, color: const Color(0xFF67E8F9)),
              ),
              Positioned(
                bottom: 35 + dy * 0.6,
                left: 30,
                child: _buildBadgeDot(
                  color: widget.accentColor.withValues(alpha: 0.6),
                  size: 10,
                ),
              ),
              Positioned(
                bottom: 45 - dy * 0.3,
                right: 35,
                child: _buildBadgeDot(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.7),
                  size: 8,
                ),
              ),

              // ── LAYER 1: BACK ENVELOPE (Angled Left -13°) ──
              Transform.translate(
                offset: Offset(
                  -30 * (1.0 - _backEnvelopeEntrance.value),
                  -50 * (1.0 - _backEnvelopeEntrance.value) + (dy * 0.5),
                ),
                child: Transform.rotate(
                  angle: -13 * (math.pi / 180),
                  child: Opacity(
                    opacity: _backEnvelopeEntrance.value.clamp(0.0, 1.0),
                    child: _buildEnvelopeCard(
                      width: widget.width * 0.62,
                      height: widget.height * 0.48,
                      bgColor: const Color(0xFF1E1E24),
                      borderColor: const Color(0xFF383842),
                      stampColor: const Color(0xFF38BDF8),
                      stampLabel: 'HR PASS',
                      hasLetter: true,
                      letterTag: 'CV ATS • 98%',
                    ),
                  ),
                ),
              ),

              // ── LAYER 2: MID ENVELOPE (Angled Right +11°) ──
              Transform.translate(
                offset: Offset(
                  35 * (1.0 - _midEnvelopeEntrance.value),
                  -35 * (1.0 - _midEnvelopeEntrance.value) - (dy * 0.6),
                ),
                child: Transform.rotate(
                  angle: 11 * (math.pi / 180),
                  child: Opacity(
                    opacity: _midEnvelopeEntrance.value.clamp(0.0, 1.0),
                    child: _buildEnvelopeCard(
                      width: widget.width * 0.68,
                      height: widget.height * 0.50,
                      bgColor: const Color(0xFF26262E),
                      borderColor: const Color(0xFF454552),
                      stampColor: const Color(0xFF4ADE80),
                      stampLabel: 'INTERVIEW',
                      hasLetter: true,
                      letterTag: widget.topBadgeText,
                    ),
                  ),
                ),
              ),

              // ── LAYER 3: FRONT HERO ENVELOPE (Center Hero -2°) ──
              Transform.translate(
                offset: Offset(
                  0,
                  30 * (1.0 - _frontEnvelopeEntrance.value) + dy,
                ),
                child: Transform.rotate(
                  angle: -2 * (math.pi / 180),
                  child: ScaleTransition(
                    scale: _frontEnvelopeEntrance,
                    child: _buildHeroEnvelopeCard(
                      width: widget.width * 0.74,
                      height: widget.height * 0.54,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSparkle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.4,
          height: size * 0.4,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeDot({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildEnvelopeCard({
    required double width,
    required double height,
    required Color bgColor,
    required Color borderColor,
    required Color stampColor,
    required String stampLabel,
    required bool hasLetter,
    required String letterTag,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Peeking Letter inside
          if (hasLetter)
            Positioned(
              top: -14,
              left: 18,
              right: 18,
              height: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  border: Border.all(color: const Color(0xFFE5E0D5), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      letterTag,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF19191B),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: stampColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Envelope Flap Lines
          CustomPaint(
            size: Size(width, height),
            painter: _EnvelopeFlapPainter(
              lineColor: borderColor.withValues(alpha: 0.7),
            ),
          ),

          // Stamp in Top-Right
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: stampColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: stampColor.withValues(alpha: 0.5), width: 1),
              ),
              child: Text(
                stampLabel,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: stampColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroEnvelopeCard({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E2D5), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Envelope Flap Pattern
          CustomPaint(
            size: Size(width, height),
            painter: _EnvelopeFlapPainter(
              lineColor: const Color(0xFFDCD5C5),
            ),
          ),

          // Peeking Letter Header
          Positioned(
            top: 14,
            left: 18,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.heroBadgeText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stamp on Top Right
          Positioned(
            top: 14,
            right: 18,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF19191B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                size: 16,
                color: Color(0xFFFFD54F),
              ),
            ),
          ),

          // Cute Envelope Mascot Eyes & Smile in Center
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEye(),
                    const SizedBox(width: 22),
                    _buildEye(),
                  ],
                ),
                const SizedBox(height: 6),
                // Sweet Smile
                Container(
                  width: 18,
                  height: 9,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF19191B),
                        width: 2.2,
                      ),
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                ),
                const SizedBox(height: 4),
                // Blushing cheeks
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBlush(),
                    const SizedBox(width: 32),
                    _buildBlush(),
                  ],
                ),
              ],
            ),
          ),

          // Wax Seal Badge at the bottom center fold
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF19191B),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: Color(0xFFFFD54F),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'NGELAMAR',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: 7,
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFF19191B),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildBlush() {
    return Container(
      width: 10,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFFDA4AF).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// Custom painter for crisp envelope triangle fold creases.
class _EnvelopeFlapPainter extends CustomPainter {
  final Color lineColor;

  _EnvelopeFlapPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Top-left to center
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.5, size.height * 0.44);
    // Top-right to center
    path.lineTo(size.width, 0);

    // Bottom-left to center
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.40, size.height * 0.50);

    // Bottom-right to center
    path.moveTo(size.width, size.height);
    path.lineTo(size.width * 0.60, size.height * 0.50);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EnvelopeFlapPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
