import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Vector rendering of the PRO King Envelope Mascot
/// with shining golden crown, rotating victory star, pulsing glow, and orbiting "+" sparkle accents.
class ProKingEnvelopeMascot extends StatefulWidget {
  final double width;
  final double height;

  const ProKingEnvelopeMascot({super.key, this.width = 240, this.height = 180});

  @override
  State<ProKingEnvelopeMascot> createState() => _ProKingEnvelopeMascotState();
}

class _ProKingEnvelopeMascotState extends State<ProKingEnvelopeMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _ProKingPainter(progress: 0),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _ProKingPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ProKingPainter extends CustomPainter {
  final double progress;

  _ProKingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
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

    final blackFill = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.fill;
    final goldFill = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final bobY = math.sin(t) * 5.5 * scale;
    final starRotation = t;

    // ── 1. ANIMATED ORBITING "+" SPARKLES (++++ Constellation) ──
    void drawPlus(Offset center, double s, Color color, double phase) {
      final dynamicSize = s * (0.85 + 0.3 * math.sin(t + phase));
      final pPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * scale
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx - dynamicSize * scale, center.dy),
        Offset(center.dx + dynamicSize * scale, center.dy),
        pPaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - dynamicSize * scale),
        Offset(center.dx, center.dy + dynamicSize * scale),
        pPaint,
      );
    }

    // Top-Left Plus
    drawPlus(
      Offset((28 + math.sin(t) * 3) * scale, (32 + math.cos(t) * 3) * scale),
      9,
      const Color(0xFFF59E0B),
      0,
    );
    drawPlus(
      Offset((52 - math.cos(t) * 3) * scale, (18 + math.sin(t) * 3) * scale),
      5,
      const Color(0xFF5C44E4),
      1.5,
    );

    // Top-Right Plus
    drawPlus(
      Offset((214 + math.cos(t) * 4) * scale, (30 + math.sin(t) * 4) * scale),
      10,
      const Color(0xFFF59E0B),
      3.0,
    );
    drawPlus(
      Offset((190 + math.sin(t) * 2) * scale, (16 - math.cos(t) * 2) * scale),
      6,
      const Color(0xFF1E8E3E),
      4.5,
    );

    // Bottom Sparkles
    drawPlus(
      Offset(22 * scale, (132 + math.sin(t) * 3) * scale),
      7,
      const Color(0xFF5C44E4),
      2.0,
    );
    drawPlus(
      Offset(218 * scale, (126 - math.cos(t) * 3) * scale),
      8,
      const Color(0xFFF59E0B),
      5.0,
    );

    // ── 2. LEGS & SHOES ──
    final leftLeg = Path()
      ..moveTo(85 * scale, 125 * scale)
      ..lineTo(75 * scale, 155 * scale);
    canvas.drawPath(leftLeg, strokePaint);
    final leftShoe = Path()
      ..moveTo(60 * scale, 150 * scale)
      ..lineTo(90 * scale, 150 * scale)
      ..lineTo(85 * scale, 168 * scale)
      ..lineTo(52 * scale, 168 * scale)
      ..close();
    canvas.drawPath(leftShoe, bodyPaint);
    canvas.drawPath(leftShoe, strokePaint);
    canvas.drawLine(
      Offset(54 * scale, 163 * scale),
      Offset(83 * scale, 163 * scale),
      strokePaint,
    );

    final rightLeg = Path()
      ..moveTo(155 * scale, 125 * scale)
      ..lineTo(165 * scale, 155 * scale);
    canvas.drawPath(rightLeg, strokePaint);
    final rightShoe = Path()
      ..moveTo(150 * scale, 150 * scale)
      ..lineTo(180 * scale, 150 * scale)
      ..lineTo(188 * scale, 168 * scale)
      ..lineTo(155 * scale, 168 * scale)
      ..close();
    canvas.drawPath(rightShoe, bodyPaint);
    canvas.drawPath(rightShoe, strokePaint);
    canvas.drawLine(
      Offset(157 * scale, 163 * scale),
      Offset(186 * scale, 163 * scale),
      strokePaint,
    );

    // ── 3. BODY WITH VICTORY BREATHING/BOB ──
    canvas.save();
    canvas.translate(0, bobY);

    final envRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(55 * scale, 48 * scale, 130 * scale, 82 * scale),
      Radius.circular(16 * scale),
    );
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    // Fold lines
    final flapTop = Path()
      ..moveTo(57 * scale, 50 * scale)
      ..lineTo(120 * scale, 92 * scale)
      ..lineTo(183 * scale, 50 * scale);
    canvas.drawPath(flapTop, strokePaint);
    final flapBottom = Path()
      ..moveTo(57 * scale, 128 * scale)
      ..lineTo(105 * scale, 90 * scale);
    canvas.drawPath(flapBottom, strokePaint);
    final flapBottomRight = Path()
      ..moveTo(183 * scale, 128 * scale)
      ..lineTo(135 * scale, 90 * scale);
    canvas.drawPath(flapBottomRight, strokePaint);

    // Golden Crown on Top
    final crownPath = Path()
      ..moveTo(95 * scale, 48 * scale)
      ..lineTo(88 * scale, 22 * scale)
      ..lineTo(108 * scale, 34 * scale)
      ..lineTo(120 * scale, 14 * scale)
      ..lineTo(132 * scale, 34 * scale)
      ..lineTo(152 * scale, 22 * scale)
      ..lineTo(145 * scale, 48 * scale)
      ..close();
    canvas.drawPath(crownPath, goldFill);
    canvas.drawPath(crownPath, strokePaint);

    canvas.drawCircle(Offset(88 * scale, 22 * scale), 2.5 * scale, blackFill);
    canvas.drawCircle(Offset(120 * scale, 14 * scale), 3.5 * scale, blackFill);
    canvas.drawCircle(Offset(152 * scale, 22 * scale), 2.5 * scale, blackFill);

    // Joyful Face
    final leftEye = Path()
      ..moveTo(92 * scale, 76 * scale)
      ..quadraticBezierTo(98 * scale, 68 * scale, 104 * scale, 76 * scale);
    canvas.drawPath(leftEye, strokePaint);
    final rightEye = Path()
      ..moveTo(136 * scale, 76 * scale)
      ..quadraticBezierTo(142 * scale, 68 * scale, 148 * scale, 76 * scale);
    canvas.drawPath(rightEye, strokePaint);

    final smile = Path()
      ..moveTo(112 * scale, 82 * scale)
      ..quadraticBezierTo(120 * scale, 92 * scale, 128 * scale, 82 * scale);
    canvas.drawPath(smile, strokePaint);

    canvas.drawOval(
      Rect.fromLTWH(88 * scale, 80 * scale, 12 * scale, 6 * scale),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(140 * scale, 80 * scale, 12 * scale, 6 * scale),
      blushPaint,
    );

    // Left Arm (Raised victory gesture)
    final leftArm = Path()
      ..moveTo(55 * scale, 85 * scale)
      ..cubicTo(
        32 * scale,
        75 * scale,
        25 * scale,
        55 * scale,
        35 * scale,
        42 * scale,
      );
    canvas.drawPath(leftArm, strokePaint);
    canvas.drawCircle(Offset(35 * scale, 42 * scale), 9 * scale, bodyPaint);
    canvas.drawCircle(Offset(35 * scale, 42 * scale), 9 * scale, strokePaint);

    // Right Arm (Holding Rotating Golden Star)
    final rightArm = Path()
      ..moveTo(185 * scale, 85 * scale)
      ..cubicTo(
        208 * scale,
        75 * scale,
        215 * scale,
        55 * scale,
        205 * scale,
        42 * scale,
      );
    canvas.drawPath(rightArm, strokePaint);
    canvas.drawCircle(Offset(205 * scale, 42 * scale), 9 * scale, bodyPaint);
    canvas.drawCircle(Offset(205 * scale, 42 * scale), 9 * scale, strokePaint);

    // Rotating Golden Star
    canvas.save();
    canvas.translate(205 * scale, 28 * scale);
    canvas.rotate(starRotation * 0.5);

    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 18) * math.pi / 180;
      final outerR = 12.5 * scale;
      final innerR = 5.8 * scale;
      final x1 = outerR * math.cos(angle);
      final y1 = outerR * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x1, y1);
      } else {
        starPath.lineTo(x1, y1);
      }
      final nextAngle = angle + 36 * math.pi / 180;
      final x2 = innerR * math.cos(nextAngle);
      final y2 = innerR * math.sin(nextAngle);
      starPath.lineTo(x2, y2);
    }
    starPath.close();
    canvas.drawPath(starPath, goldFill);
    canvas.drawPath(starPath, strokePaint);

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProKingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
