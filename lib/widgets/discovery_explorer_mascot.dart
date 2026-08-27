import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Explorer Mascot with Magnifying Glass & Floating Sparkles for Job Discovery Welcome.
class DiscoveryExplorerMascot extends StatefulWidget {
  final double width;
  final double height;

  const DiscoveryExplorerMascot({
    super.key,
    this.width = 240,
    this.height = 180,
  });

  @override
  State<DiscoveryExplorerMascot> createState() =>
      _DiscoveryExplorerMascotState();
}

class _DiscoveryExplorerMascotState extends State<DiscoveryExplorerMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
        painter: _DiscoveryExplorerPainter(progress: 0),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _DiscoveryExplorerPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _DiscoveryExplorerPainter extends CustomPainter {
  final double progress;

  _DiscoveryExplorerPainter({required this.progress});

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
    final floatY = math.sin(t) * 6 * scale;
    final scanX = math.sin(t) * 12 * scale;

    // Sparkles Orbit
    void drawSparkle(Offset c, double s, Color col) {
      final p = Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * scale
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(c.dx - s * scale, c.dy),
        Offset(c.dx + s * scale, c.dy),
        p,
      );
      canvas.drawLine(
        Offset(c.dx, c.dy - s * scale),
        Offset(c.dx, c.dy + s * scale),
        p,
      );
    }

    drawSparkle(
      Offset((35 + math.cos(t) * 5) * scale, (35 + math.sin(t) * 5) * scale),
      7,
      const Color(0xFF0E7090),
    );
    drawSparkle(
      Offset((205 - math.cos(t) * 5) * scale, (40 + math.sin(t) * 5) * scale),
      8,
      const Color(0xFFF59E0B),
    );
    drawSparkle(
      Offset((215 + math.sin(t) * 4) * scale, (120 - math.cos(t) * 4) * scale),
      6,
      const Color(0xFF5C44E4),
    );

    // Legs
    final leftLeg = Path()
      ..moveTo(85 * scale, 120 * scale)
      ..lineTo(75 * scale, 150 * scale);
    canvas.drawPath(leftLeg, strokePaint);
    final leftShoe = Path()
      ..moveTo(60 * scale, 146 * scale)
      ..lineTo(90 * scale, 146 * scale)
      ..lineTo(85 * scale, 162 * scale)
      ..lineTo(54 * scale, 162 * scale)
      ..close();
    canvas.drawPath(leftShoe, bodyPaint);
    canvas.drawPath(leftShoe, strokePaint);

    final rightLeg = Path()
      ..moveTo(155 * scale, 120 * scale)
      ..lineTo(165 * scale, 150 * scale);
    canvas.drawPath(rightLeg, strokePaint);
    final rightShoe = Path()
      ..moveTo(150 * scale, 146 * scale)
      ..lineTo(180 * scale, 146 * scale)
      ..lineTo(186 * scale, 162 * scale)
      ..lineTo(154 * scale, 162 * scale)
      ..close();
    canvas.drawPath(rightShoe, bodyPaint);
    canvas.drawPath(rightShoe, strokePaint);

    // Body
    canvas.save();
    canvas.translate(0, floatY);

    final envRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(55 * scale, 48 * scale, 130 * scale, 80 * scale),
      Radius.circular(16 * scale),
    );
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    final flapTop = Path()
      ..moveTo(57 * scale, 50 * scale)
      ..lineTo(120 * scale, 90 * scale)
      ..lineTo(183 * scale, 50 * scale);
    canvas.drawPath(flapTop, strokePaint);

    // Curious Looking Eyes (Moving with scanX)
    final eyeOffsetX = scanX * 0.25;
    canvas.drawCircle(
      Offset((100 + eyeOffsetX) * scale, 72 * scale),
      5 * scale,
      blackFill,
    );
    canvas.drawCircle(
      Offset((102 + eyeOffsetX) * scale, 70 * scale),
      1.8 * scale,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      Offset((140 + eyeOffsetX) * scale, 72 * scale),
      5 * scale,
      blackFill,
    );
    canvas.drawCircle(
      Offset((142 + eyeOffsetX) * scale, 70 * scale),
      1.8 * scale,
      Paint()..color = Colors.white,
    );

    // Happy O mouth
    canvas.drawCircle(Offset(120 * scale, 84 * scale), 3.5 * scale, blackFill);

    // Left Arm
    final leftArm = Path()
      ..moveTo(55 * scale, 85 * scale)
      ..cubicTo(
        35 * scale,
        75 * scale,
        28 * scale,
        90 * scale,
        38 * scale,
        102 * scale,
      );
    canvas.drawPath(leftArm, strokePaint);
    canvas.drawCircle(Offset(38 * scale, 102 * scale), 8 * scale, bodyPaint);
    canvas.drawCircle(Offset(38 * scale, 102 * scale), 8 * scale, strokePaint);

    // Right Arm Holding Magnifying Glass (Scanning motion)
    final glassX = (185 + scanX) * scale;
    final glassY = 65 * scale;
    final rightArm = Path()
      ..moveTo(185 * scale, 85 * scale)
      ..lineTo(glassX, glassY + 20 * scale);
    canvas.drawPath(rightArm, strokePaint);

    // Magnifying Glass Handle & Ring
    final glassHandle = Path()
      ..moveTo(glassX, glassY + 20 * scale)
      ..lineTo(glassX + 16 * scale, glassY + 36 * scale);
    canvas.drawPath(
      glassHandle,
      Paint()
        ..color = const Color(0xFF5C44E4)
        ..strokeWidth = 4.5 * scale
        ..strokeCap = StrokeCap.round,
    );

    final glassCircle = Paint()
      ..color = const Color(0xFF0E7090).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(glassX, glassY), 16 * scale, glassCircle);
    canvas.drawCircle(Offset(glassX, glassY), 16 * scale, strokePaint);
    canvas.drawCircle(
      Offset(glassX - 4 * scale, glassY - 4 * scale),
      3 * scale,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiscoveryExplorerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
