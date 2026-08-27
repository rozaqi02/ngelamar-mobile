import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ultra-smooth, fluid, and natural Running Envelope Mascot.
/// Features authentic multi-joint cartoon running kinematics:
/// - Natural thigh & knee flexion/extension cycle
/// - Coordinated arm pumping
/// - Gentle harmonic body bounce
/// - Soft trailing dust puffs
class RunningEnvelopeMascot extends StatefulWidget {
  final double width;
  final double height;
  final bool animate;

  const RunningEnvelopeMascot({
    super.key,
    this.width = 240,
    this.height = 180,
    this.animate = true,
  });

  @override
  State<RunningEnvelopeMascot> createState() => _RunningEnvelopeMascotState();
}

class _RunningEnvelopeMascotState extends State<RunningEnvelopeMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920), // Natural, lively jog tempo
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RunningEnvelopeMascot oldWidget) {
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
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _OrganicRunningMascotPainter(progress: 0),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _OrganicRunningMascotPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _OrganicRunningMascotPainter extends CustomPainter {
  final double progress;

  _OrganicRunningMascotPainter({required this.progress});

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

    // Harmonious body bounce (2 smooth arcs per stride cycle)
    final bodyBob = -math.sin(t * 2).abs() * 5.5 * scale;
    const forwardLean =
        -0.12; // Forward tilt towards the left (running direction)

    // ── 0. TRAILING DUST & SPEED PUFFS (BEHIND FEET TO THE RIGHT) ──
    final dustPaint = Paint()
      ..color = const Color(0xFFD5CEBF).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    // 3 layered trailing puffs billowing behind to the right
    for (int i = 0; i < 3; i++) {
      final pPhase = (progress + i * 0.33) % 1.0;
      final pX = (175 + pPhase * 45) * scale;
      final pY = (156 - pPhase * 12 + math.sin(t + i) * 3) * scale;
      final pRadius = (7.5 - pPhase * 5.5) * scale;
      if (pRadius > 0.6) {
        canvas.drawCircle(Offset(pX, pY), pRadius, dustPaint);
      }
    }

    // Horizontal speed trail lines behind the envelope to the right
    final speedLinePaint = Paint()
      ..color = const Color(0xFFD5CEBF).withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset((200 + math.sin(t) * 8) * scale, 75 * scale + bodyBob),
      Offset((222 + math.sin(t) * 8) * scale, 75 * scale + bodyBob),
      speedLinePaint,
    );
    canvas.drawLine(
      Offset((192 + math.cos(t) * 6) * scale, 95 * scale + bodyBob),
      Offset((212 + math.cos(t) * 6) * scale, 95 * scale + bodyBob),
      speedLinePaint,
    );

    // Helper: Draw a cartoon running leg with thigh, knee bend, and shoe facing LEFT
    void drawLeg({
      required double hipX,
      required double hipY,
      required double phase,
      required bool isBackLeg,
    }) {
      final legT = t + phase;
      final sinT = math.sin(legT);
      final cosT = math.cos(legT);

      // Thigh rotation: forward swing (- left), backward swing (+ right)
      final thighAngle = -sinT * 0.60;

      // Knee bend: bends backwards (+ right) when leg is trailing (-cosT), straightens on strike
      final kneeBend = (cosT < 0)
          ? (-cosT * 0.90)
          : (sinT * 0.25).clamp(0.0, 0.55);

      final thighLength = 23.0 * scale;
      final shinLength = 23.0 * scale;

      // Hip origin
      final hX = hipX * scale;
      final hY = (hipY * scale) + bodyBob;

      // Knee joint
      final kX = hX + thighLength * math.sin(thighAngle);
      final kY = hY + thighLength * math.cos(thighAngle);

      // Ankle joint
      final shinAngle = thighAngle + kneeBend;
      final aX = kX + shinLength * math.sin(shinAngle);
      final aY = kY + shinLength * math.cos(shinAngle);

      // Draw leg stroke
      final legPath = Path()
        ..moveTo(hX, hY)
        ..lineTo(kX, kY)
        ..lineTo(aX, aY);
      canvas.drawPath(legPath, strokePaint);

      // Shoe angle: pointed forward to the LEFT
      final footTilt = (shinAngle * 0.55) - (sinT > 0 ? 0.20 : -0.25);

      canvas.save();
      canvas.translate(aX, aY);
      canvas.rotate(footTilt);

      // Shoe facing LEFT (toe is on negative X, heel on positive X)
      final shoePath = Path()
        ..moveTo(12 * scale, -2 * scale)
        ..lineTo(-16 * scale, -2 * scale)
        ..quadraticBezierTo(-22 * scale, 6 * scale, -18 * scale, 12 * scale)
        ..lineTo(14 * scale, 12 * scale)
        ..quadraticBezierTo(18 * scale, 5 * scale, 12 * scale, -2 * scale)
        ..close();

      canvas.drawPath(shoePath, bodyPaint);
      canvas.drawPath(shoePath, strokePaint);

      // Sole line
      canvas.drawLine(
        Offset(15 * scale, 8 * scale),
        Offset(-18 * scale, 8 * scale),
        strokePaint,
      );

      canvas.restore();
    }

    // ── 1. DRAW BACK (RIGHT) LEG ──
    drawLeg(
      hipX: 148,
      hipY: 120,
      phase: math.pi, // Opposite stride phase
      isBackLeg: true,
    );

    // ── 2. DRAW BACK (RIGHT) ARM (SWINGING BACKWARD TO RIGHT) ──
    final armCycle = math.sin(t);
    final rightArmAngle = armCycle * 0.60;
    final rightArmPivotX = 168 * scale;
    final rightArmPivotY = 80 * scale + bodyBob;

    canvas.save();
    canvas.translate(rightArmPivotX, rightArmPivotY);
    canvas.rotate(rightArmAngle);

    final rightArmPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(14 * scale, 16 * scale, 22 * scale, 6 * scale);
    canvas.drawPath(rightArmPath, strokePaint);
    canvas.drawCircle(Offset(22 * scale, 6 * scale), 7.5 * scale, bodyPaint);
    canvas.drawCircle(Offset(22 * scale, 6 * scale), 7.5 * scale, strokePaint);
    canvas.restore();

    // ── 3. MAIN ENVELOPE BODY (LEANING FORWARD TO LEFT) ──
    canvas.save();
    canvas.translate(118 * scale, 85 * scale + bodyBob);
    canvas.rotate(forwardLean);
    canvas.translate(-118 * scale, -85 * scale);

    // Envelope Body Rounded Rect
    final envRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(54 * scale, 44 * scale, 128 * scale, 80 * scale),
      Radius.circular(16 * scale),
    );
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    // Top Flap
    final flapTop = Path()
      ..moveTo(55 * scale, 46 * scale)
      ..lineTo(118 * scale, 86 * scale)
      ..lineTo(181 * scale, 46 * scale);
    canvas.drawPath(flapTop, strokePaint);

    // Bottom Flaps
    final flapBottomL = Path()
      ..moveTo(55 * scale, 122 * scale)
      ..lineTo(104 * scale, 86 * scale);
    canvas.drawPath(flapBottomL, strokePaint);

    final flapBottomR = Path()
      ..moveTo(181 * scale, 122 * scale)
      ..lineTo(132 * scale, 86 * scale);
    canvas.drawPath(flapBottomR, strokePaint);

    // Expressive Eyes Looking FORWARD TO THE LEFT
    // Left Eye
    canvas.drawOval(
      Rect.fromLTWH(86 * scale, 60 * scale, 9 * scale, 11 * scale),
      blackFill,
    );
    canvas.drawCircle(
      Offset(88 * scale, 63 * scale),
      2.5 * scale,
      Paint()..color = Colors.white,
    );

    // Right Eye
    canvas.drawOval(
      Rect.fromLTWH(122 * scale, 60 * scale, 9 * scale, 11 * scale),
      blackFill,
    );
    canvas.drawCircle(
      Offset(124 * scale, 63 * scale),
      2.5 * scale,
      Paint()..color = Colors.white,
    );

    // Cheerful Open Smile facing left
    final smilePath = Path()
      ..moveTo(98 * scale, 75 * scale)
      ..quadraticBezierTo(109 * scale, 88 * scale, 120 * scale, 75 * scale)
      ..close();
    canvas.drawPath(smilePath, blackFill);

    // Rosy Cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.75);
    canvas.drawOval(
      Rect.fromLTWH(76 * scale, 72 * scale, 11 * scale, 6 * scale),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(126 * scale, 72 * scale, 11 * scale, 6 * scale),
      blushPaint,
    );

    canvas.restore();

    // ── 4. DRAW FRONT (LEFT) LEG ──
    drawLeg(
      hipX: 96,
      hipY: 120,
      phase: 0, // Primary stride phase
      isBackLeg: false,
    );

    // ── 5. DRAW FRONT (LEFT) ARM (PUMPING FORWARD TO LEFT) ──
    final leftArmAngle = -armCycle * 0.60;
    final leftArmPivotX = 64 * scale;
    final leftArmPivotY = 80 * scale + bodyBob;

    canvas.save();
    canvas.translate(leftArmPivotX, leftArmPivotY);
    canvas.rotate(leftArmAngle);

    final leftArmPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-16 * scale, 14 * scale, -24 * scale, 4 * scale);
    canvas.drawPath(leftArmPath, strokePaint);
    canvas.drawCircle(Offset(-24 * scale, 4 * scale), 7.5 * scale, bodyPaint);
    canvas.drawCircle(Offset(-24 * scale, 4 * scale), 7.5 * scale, strokePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrganicRunningMascotPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
