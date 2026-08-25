import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Crying Envelope Mascot for Empty State on Homepage.
/// Features sad drooping eyes, trembling mouth, shivering body, and animated falling tear drops.
class CryingEnvelopeMascot extends StatefulWidget {
  final double width;
  final double height;

  const CryingEnvelopeMascot({super.key, this.width = 220, this.height = 170});

  @override
  State<CryingEnvelopeMascot> createState() => _CryingEnvelopeMascotState();
}

class _CryingEnvelopeMascotState extends State<CryingEnvelopeMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _CryingMascotPainter(progress: 0),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _CryingMascotPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _CryingMascotPainter extends CustomPainter {
  final double progress;

  _CryingMascotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 220.0;
    final t = progress * 2 * math.pi;

    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shiver = math.sin(t * 4) * 1.5 * scale; // Sobbing vibration

    // ── LEGS (Sitting sadly / slumped) ──
    final leftLeg = Path()
      ..moveTo(80 * scale, 120 * scale)
      ..lineTo(70 * scale, 148 * scale);
    canvas.drawPath(leftLeg, strokePaint);

    final leftShoe = Path()
      ..moveTo(55 * scale, 142 * scale)
      ..lineTo(85 * scale, 142 * scale)
      ..lineTo(80 * scale, 158 * scale)
      ..lineTo(48 * scale, 158 * scale)
      ..close();
    canvas.drawPath(leftShoe, bodyPaint);
    canvas.drawPath(leftShoe, strokePaint);

    final rightLeg = Path()
      ..moveTo(140 * scale, 120 * scale)
      ..lineTo(150 * scale, 148 * scale);
    canvas.drawPath(rightLeg, strokePaint);

    final rightShoe = Path()
      ..moveTo(135 * scale, 142 * scale)
      ..lineTo(165 * scale, 142 * scale)
      ..lineTo(172 * scale, 158 * scale)
      ..lineTo(140 * scale, 158 * scale)
      ..close();
    canvas.drawPath(rightShoe, bodyPaint);
    canvas.drawPath(rightShoe, strokePaint);

    // ── MAIN BODY ──
    canvas.save();
    canvas.translate(0, shiver);

    // Drooping Arms (Wiping tears with hands near face)
    final leftArm = Path()
      ..moveTo(50 * scale, 82 * scale)
      ..quadraticBezierTo(58 * scale, 65 * scale, 76 * scale, 75 * scale);
    canvas.drawPath(leftArm, strokePaint);
    canvas.drawCircle(Offset(76 * scale, 75 * scale), 8 * scale, bodyPaint);
    canvas.drawCircle(Offset(76 * scale, 75 * scale), 8 * scale, strokePaint);

    final rightArm = Path()
      ..moveTo(170 * scale, 82 * scale)
      ..quadraticBezierTo(162 * scale, 65 * scale, 144 * scale, 75 * scale);
    canvas.drawPath(rightArm, strokePaint);
    canvas.drawCircle(Offset(144 * scale, 75 * scale), 8 * scale, bodyPaint);
    canvas.drawCircle(Offset(144 * scale, 75 * scale), 8 * scale, strokePaint);

    final envRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(50 * scale, 45 * scale, 120 * scale, 78 * scale),
      Radius.circular(16 * scale),
    );
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    // Flap lines
    final flapTop = Path()
      ..moveTo(52 * scale, 47 * scale)
      ..lineTo(110 * scale, 85 * scale)
      ..lineTo(168 * scale, 47 * scale);
    canvas.drawPath(flapTop, strokePaint);

    // ── CRYING FACE ──
    // Sad Drooping Closed Eyes T_T
    final leftEye = Path()
      ..moveTo(84 * scale, 70 * scale)
      ..lineTo(98 * scale, 74 * scale);
    canvas.drawPath(leftEye, strokePaint);

    final rightEye = Path()
      ..moveTo(136 * scale, 74 * scale)
      ..lineTo(122 * scale, 70 * scale);
    canvas.drawPath(rightEye, strokePaint);

    // Wobbly Trembling Mouth
    final mouthY = 88 * scale + math.sin(t * 6) * 1.2 * scale;
    final mouth = Path()
      ..moveTo(102 * scale, mouthY)
      ..quadraticBezierTo(110 * scale, mouthY - 6 * scale, 118 * scale, mouthY);
    canvas.drawPath(mouth, strokePaint);

    // Blushing Red Nose / Cheeks
    final blush = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.65);
    canvas.drawCircle(Offset(110 * scale, 80 * scale), 4 * scale, blush);
    canvas.drawOval(
      Rect.fromLTWH(80 * scale, 78 * scale, 10 * scale, 5 * scale),
      blush,
    );
    canvas.drawOval(
      Rect.fromLTWH(130 * scale, 78 * scale, 10 * scale, 5 * scale),
      blush,
    );

    // ── TEAR STREAMS & FALLING TEAR DROPS ──
    final tearPaint = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    void drawTearDrop(Offset pos, double tearSize) {
      final p = Path()
        ..moveTo(pos.dx, pos.dy - tearSize)
        ..quadraticBezierTo(
          pos.dx + tearSize,
          pos.dy,
          pos.dx,
          pos.dy + tearSize,
        )
        ..quadraticBezierTo(
          pos.dx - tearSize,
          pos.dy,
          pos.dx,
          pos.dy - tearSize,
        )
        ..close();
      canvas.drawPath(p, tearPaint);
    }

    // Left Tears
    final leftTearY1 = (75 + progress * 55) * scale;
    drawTearDrop(
      Offset(88 * scale, leftTearY1),
      4.5 * scale * (1 - progress * 0.3),
    );

    final leftTearY2 = (75 + ((progress + 0.5) % 1.0) * 55) * scale;
    drawTearDrop(
      Offset(84 * scale, leftTearY2),
      3.8 * scale * (1 - ((progress + 0.5) % 1.0) * 0.3),
    );

    // Right Tears
    final rightTearY1 = (75 + progress * 55) * scale;
    drawTearDrop(
      Offset(132 * scale, rightTearY1),
      4.5 * scale * (1 - progress * 0.3),
    );

    final rightTearY2 = (75 + ((progress + 0.5) % 1.0) * 55) * scale;
    drawTearDrop(
      Offset(136 * scale, rightTearY2),
      3.8 * scale * (1 - ((progress + 0.5) % 1.0) * 0.3),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CryingMascotPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
