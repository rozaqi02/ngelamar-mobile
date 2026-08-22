import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Confused / Searching Envelope Mascot.
/// Menampilkan maskot amplop yang sedang bingung mencari data lamaran:
/// - Kepala/badan miring bingung (tilted pose)
/// - Tangan menggaruk kepala bingung & tangan memegang kaca pembesar
/// - Mata melirik mencari-cari
/// - 3 tanda tanya "?" animasi melayang bergelombang di atas kepala
class ConfusedEnvelopeMascot extends StatefulWidget {
  final double width;
  final double height;
  final bool animate;

  const ConfusedEnvelopeMascot({
    super.key,
    this.width = 220,
    this.height = 180,
    this.animate = true,
  });

  @override
  State<ConfusedEnvelopeMascot> createState() => _ConfusedEnvelopeMascotState();
}

class _ConfusedEnvelopeMascotState extends State<ConfusedEnvelopeMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ConfusedEnvelopeMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _ConfusedMascotPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ConfusedMascotPainter extends CustomPainter {
  final double progress;

  _ConfusedMascotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 220.0;
    final t = progress * 2 * math.pi;

    canvas.save();
    canvas.scale(scale);

    // Subtle breathing bounce
    final breatheY = math.sin(t) * 3.0;
    // Head tilt angle oscillation (wondering tilt)
    final tiltAngle = (math.sin(t) * 0.08) - 0.06;
    // Scratching hand wobble
    final scratchAngle = math.sin(t * 4) * 0.15;

    // ── 0. GROUND SHADOW ──
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(110, 165), width: 90, height: 12),
      shadowPaint,
    );

    // ── 1. LEGS ──
    final legPaint = Paint()
      ..color = const Color(0xFF19191B)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shoePaint = Paint()
      ..color = const Color(0xFF19191B)
      ..style = PaintingStyle.fill;

    // Left leg
    canvas.drawLine(
      Offset(88, 128 + breatheY),
      const Offset(84, 158),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(80, 160), width: 18, height: 9),
        const Radius.circular(4),
      ),
      shoePaint,
    );

    // Right leg
    canvas.drawLine(
      Offset(132, 128 + breatheY),
      const Offset(136, 158),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(140, 160), width: 18, height: 9),
        const Radius.circular(4),
      ),
      shoePaint,
    );

    // ── 2. ENVELOPE BODY (TILTED) ──
    canvas.save();
    final bodyCenter = Offset(110, 85 + breatheY);
    canvas.translate(bodyCenter.dx, bodyCenter.dy);
    canvas.rotate(tiltAngle);

    final bodyPaint = Paint()
      ..color = const Color(0xFFFAF9F6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF19191B)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    final envelopeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 108, height: 76),
      const Radius.circular(14),
    );

    // Soft outer shadow
    final bodyShadow = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(envelopeRect, bodyShadow);

    canvas.drawRRect(envelopeRect, bodyPaint);
    canvas.drawRRect(envelopeRect, borderPaint);

    // Flap fold lines
    final foldPaint = Paint()
      ..color = const Color(0xFFE5DFD3)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final foldPath = Path()
      ..moveTo(-54, -38)
      ..lineTo(0, 6)
      ..lineTo(54, -38);
    canvas.drawPath(foldPath, foldPaint);

    // ── 3. CONFUSED / WONDERING FACE ──
    // Eyes looking up-left and around
    final lookX = math.cos(t) * 2.5;
    final lookY = -2.0 + math.sin(t) * 1.2;

    final eyeBasePaint = Paint()..color = const Color(0xFF19191B);

    // Left Eye (Raised eyebrow above it)
    final leftEye = const Offset(-20, -7);
    canvas.drawCircle(leftEye, 5.0, eyeBasePaint);
    canvas.drawCircle(
      Offset(leftEye.dx + lookX, leftEye.dy + lookY),
      1.8,
      Paint()..color = Colors.white,
    );

    // Raised curved left eyebrow (surprised/curious)
    final leftEyebrow = Path()
      ..moveTo(-26, -17)
      ..quadraticBezierTo(-20, -22, -14, -18);
    canvas.drawPath(
      leftEyebrow,
      Paint()
        ..color = const Color(0xFF19191B)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Right Eye (Worried/wondering lowered eyebrow)
    final rightEye = const Offset(20, -7);
    canvas.drawCircle(rightEye, 5.0, eyeBasePaint);
    canvas.drawCircle(
      Offset(rightEye.dx + lookX, rightEye.dy + lookY),
      1.8,
      Paint()..color = Colors.white,
    );

    // Wondering right eyebrow
    final rightEyebrow = Path()
      ..moveTo(14, -16)
      ..quadraticBezierTo(20, -17, 26, -13);
    canvas.drawPath(
      rightEyebrow,
      Paint()
        ..color = const Color(0xFF19191B)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-25, 3), width: 9, height: 5),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(25, 3), width: 9, height: 5),
      blushPaint,
    );

    // Wavy Confused Mouth (Squiggly `~`)
    final mouthPath = Path()
      ..moveTo(-9, 3)
      ..quadraticBezierTo(-4, 7, 0, 3)
      ..quadraticBezierTo(4, -1, 9, 3);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFF19191B)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // ── 4. LEFT ARM: SCRATCHING HEAD IN CONFUSION ──
    final armPaint = Paint()
      ..color = const Color(0xFF19191B)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leftArmPath = Path()
      ..moveTo(-52, 0)
      ..cubicTo(-70, -15, -60, -42 + scratchAngle * 10, -32, -40);
    canvas.drawPath(leftArmPath, armPaint);

    // Hand scratching top corner
    canvas.drawCircle(Offset(-30, -40 + scratchAngle * 6), 5.5, shoePaint);

    // ── 5. RIGHT ARM: HOLDING MAGNIFYING GLASS ──
    final rightArmPath = Path()
      ..moveTo(52, 2)
      ..quadraticBezierTo(68, 12, 60, 26);
    canvas.drawPath(rightArmPath, armPaint);

    // Hand
    canvas.drawCircle(const Offset(60, 26), 5.0, shoePaint);

    // Magnifying Glass
    final glassCenter = const Offset(74, 18);
    // Glass handle
    canvas.drawLine(
      const Offset(62, 24),
      glassCenter,
      Paint()
        ..color = const Color(0xFF19191B)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    // Glass rim
    final glassRimPaint = Paint()
      ..color = const Color(0xFF5C44E4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(glassCenter, 9, glassRimPaint);
    // Glass lens fill (light blue transparent)
    canvas.drawCircle(
      glassCenter,
      7.5,
      Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.35),
    );

    canvas.restore(); // Restore tilted body

    // ── 6. ANIMATED FLOATING QUESTION MARKS "?" ──
    _drawQuestionMark(
      canvas,
      Offset(150, 32 + math.sin(t) * 5),
      size: 20,
      color: const Color(0xFFF59E0B),
      rotation: 0.15,
      alpha: 0.95,
    );

    _drawQuestionMark(
      canvas,
      Offset(60, 24 + math.sin(t + 1.2) * 4),
      size: 15,
      color: const Color(0xFFA78BFA),
      rotation: -0.20,
      alpha: 0.85,
    );

    _drawQuestionMark(
      canvas,
      Offset(175, 52 + math.sin(t + 2.4) * 3),
      size: 13,
      color: const Color(0xFF38BDF8),
      rotation: 0.25,
      alpha: 0.75,
    );

    canvas.restore();
  }

  void _drawQuestionMark(
    Canvas canvas,
    Offset pos, {
    required double size,
    required Color color,
    required double rotation,
    required double alpha,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: alpha),
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ConfusedMascotPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
