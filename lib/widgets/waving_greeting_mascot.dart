import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Cheerful Waving & Greeting Envelope Mascot.
/// Pose ramah menyapa user dengan lambaian tangan aktif, senyuman ceria, pipi merona,
/// dan animasi floating bounce yang menyenangkan. Khusus untuk Welcome Screen Daftar Lamaran.
class WavingGreetingMascot extends StatefulWidget {
  final double width;
  final double height;
  final bool animate;

  const WavingGreetingMascot({
    super.key,
    this.width = 250,
    this.height = 200,
    this.animate = true,
  });

  @override
  State<WavingGreetingMascot> createState() => _WavingGreetingMascotState();
}

class _WavingGreetingMascotState extends State<WavingGreetingMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600), // Smooth greeting wave cycle
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WavingGreetingMascot oldWidget) {
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
          painter: _WavingMascotPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _WavingMascotPainter extends CustomPainter {
  final double progress;

  _WavingMascotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    final t = progress * 2 * math.pi;

    canvas.save();
    canvas.scale(scale);

    // Floating bounce
    final floatY = math.sin(t) * 4.5;
    // Waving arm oscillation (fast friendly flutter)
    final waveAngle = math.sin(t * 3) * 0.38 - 0.25;

    // ── 0. SOFT GROUND SHADOW ──
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final shadowScale = 1.0 - (floatY / 30.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(120, 185),
        width: 110 * shadowScale,
        height: 14 * shadowScale,
      ),
      shadowPaint,
    );

    // ── 1. LEGS (STANDING COMFORTABLY) ──
    final legPaint = Paint()
      ..color = const Color(0xFF19191B)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shoePaint = Paint()
      ..color = const Color(0xFF19191B)
      ..style = PaintingStyle.fill;

    // Left leg
    canvas.drawLine(
      Offset(95, 142 + floatY),
      Offset(90, 178),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(86, 180), width: 22, height: 10),
        const Radius.circular(5),
      ),
      shoePaint,
    );

    // Right leg
    canvas.drawLine(
      Offset(145, 142 + floatY),
      Offset(150, 178),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(154, 180), width: 22, height: 10),
        const Radius.circular(5),
      ),
      shoePaint,
    );

    // ── 2. ENVELOPE BODY ──
    final bodyCenter = Offset(120, 95 + floatY);

    // White envelope base
    final bodyPaint = Paint()
      ..color = const Color(0xFFFAF9F6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF19191B)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final envelopeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bodyCenter, width: 120, height: 86),
      const Radius.circular(16),
    );

    // Soft outer shadow for body
    final bodyShadow = Paint()
      ..color = const Color(0xFF5C44E4).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(envelopeRect, bodyShadow);

    canvas.drawRRect(envelopeRect, bodyPaint);
    canvas.drawRRect(envelopeRect, borderPaint);

    // Flap fold lines (triangular fold on back)
    final foldPaint = Paint()
      ..color = const Color(0xFFE5DFD3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final foldPath = Path()
      ..moveTo(bodyCenter.dx - 60, bodyCenter.dy - 43)
      ..lineTo(bodyCenter.dx, bodyCenter.dy + 8)
      ..lineTo(bodyCenter.dx + 60, bodyCenter.dy - 43);
    canvas.drawPath(foldPath, foldPaint);

    // Golden wax seal / star pin on flap
    final badgePaint = Paint()
      ..color = const Color(0xFFF8BA38)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(bodyCenter.dx, bodyCenter.dy + 8), 7, badgePaint);
    canvas.drawCircle(Offset(bodyCenter.dx, bodyCenter.dy + 8), 7, borderPaint..strokeWidth = 1.8);

    // ── 3. CUTE HAPPY FACE ──
    final eyePaint = Paint()
      ..color = const Color(0xFF19191B)
      ..style = PaintingStyle.fill;

    // Left Eye (Big Friendly Sparkle Eye)
    final leftEye = Offset(bodyCenter.dx - 22, bodyCenter.dy - 8);
    canvas.drawCircle(leftEye, 5.5, eyePaint);
    canvas.drawCircle(Offset(leftEye.dx - 1.8, leftEye.dy - 1.8), 2.0, Paint()..color = Colors.white);

    // Right Eye (Joyful Winking Eye Curve)
    final rightEyeCenter = Offset(bodyCenter.dx + 22, bodyCenter.dy - 8);
    final winkPath = Path()
      ..moveTo(rightEyeCenter.dx - 6, rightEyeCenter.dy + 1)
      ..quadraticBezierTo(rightEyeCenter.dx, rightEyeCenter.dy - 7, rightEyeCenter.dx + 6, rightEyeCenter.dy + 1);
    canvas.drawPath(
      winkPath,
      Paint()
        ..color = const Color(0xFF19191B)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Rosy Pink Cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(bodyCenter.dx - 28, bodyCenter.dy + 3), width: 11, height: 6), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(bodyCenter.dx + 28, bodyCenter.dy + 3), width: 11, height: 6), blushPaint);

    // Happy Big Smile Mouth
    final mouthPath = Path()
      ..moveTo(bodyCenter.dx - 12, bodyCenter.dy + 2)
      ..quadraticBezierTo(bodyCenter.dx, bodyCenter.dy + 14, bodyCenter.dx + 12, bodyCenter.dy + 2)
      ..close();
    canvas.drawPath(
      mouthPath,
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFF19191B)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // ── 4. LEFT ARM (RESTING HAPPILY ON HIP) ──
    final armPaint = Paint()
      ..color = const Color(0xFF19191B)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leftArmPath = Path()
      ..moveTo(bodyCenter.dx - 58, bodyCenter.dy + 5)
      ..quadraticBezierTo(bodyCenter.dx - 76, bodyCenter.dy + 18, bodyCenter.dx - 56, bodyCenter.dy + 28);
    canvas.drawPath(leftArmPath, armPaint);

    // ── 5. RIGHT ARM (WAVING HIGH & PROUD) ──
    canvas.save();
    // Pivot at shoulder
    final shoulder = Offset(bodyCenter.dx + 58, bodyCenter.dy - 6);
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(waveAngle - 0.85); // Angle up towards sky

    // Upper arm to hand
    canvas.drawLine(Offset.zero, const Offset(0, -36), armPaint);

    // Open waving hand glove
    canvas.drawCircle(const Offset(0, -38), 7.5, shoePaint);
    // 4 cute fingers
    canvas.drawCircle(const Offset(-4, -42), 3.2, shoePaint);
    canvas.drawCircle(const Offset(0, -44), 3.5, shoePaint);
    canvas.drawCircle(const Offset(4, -42), 3.2, shoePaint);
    canvas.drawCircle(const Offset(6, -37), 3.0, shoePaint);

    canvas.restore();

    // ── 6. SPARKLES & GREETING STARS AROUND MASCOT ──
    _drawSparkle(canvas, Offset(bodyCenter.dx + 65, bodyCenter.dy - 55 + floatY * 0.4), 8, const Color(0xFFF8BA38));
    _drawSparkle(canvas, Offset(bodyCenter.dx - 55, bodyCenter.dy - 40 - floatY * 0.3), 6, const Color(0xFFA78BFA));
    _drawSparkle(canvas, Offset(bodyCenter.dx + 50, bodyCenter.dy + 35 + floatY * 0.2), 5, const Color(0xFF4ADE80));

    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavingMascotPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
