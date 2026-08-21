import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================================
// 1. RUNNING ENVELOPE MASCOT (REAL RUNNING CYCLE + DUST + SPEED LINES)
// ============================================================================
class RunningEnvelopeMascot extends StatefulWidget {
  final double width;
  final double height;

  const RunningEnvelopeMascot({
    super.key,
    this.width = 220,
    this.height = 160,
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
      duration: const Duration(milliseconds: 700),
    )..repeat();
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
          painter: _RunningMascotPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _RunningMascotPainter extends CustomPainter {
  final double progress;

  _RunningMascotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 220.0;
    final angle = progress * 2 * math.pi;

    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final dustPaint = Paint()
      ..color = const Color(0xFFD6C8F8).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final speedLinePaint = Paint()
      ..color = const Color(0xFF5C44E4).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;

    // ── SPEED LINES & DUST PUFFS ──
    final dustOffset = (progress * 40) % 40;
    canvas.drawCircle(Offset((40 - dustOffset) * scale, 138 * scale), 6 * scale, dustPaint);
    canvas.drawCircle(Offset((55 - dustOffset) * scale, 144 * scale), 4 * scale, dustPaint);
    canvas.drawCircle(Offset((25 - dustOffset) * scale, 142 * scale), 3 * scale, dustPaint);

    canvas.drawLine(Offset(18 * scale, 75 * scale), Offset(42 * scale, 75 * scale), speedLinePaint);
    canvas.drawLine(Offset(10 * scale, 95 * scale), Offset(38 * scale, 95 * scale), speedLinePaint);
    canvas.drawLine(Offset(22 * scale, 115 * scale), Offset(46 * scale, 115 * scale), speedLinePaint);

    // ── LEGS (Real Running Cycle via Sine & Cosine) ──
    final leftLegPhase = math.sin(angle);
    final rightLegPhase = -leftLegPhase;
    final bobbing = (math.sin(angle * 2) * 4.0).abs() * scale;

    // Left Leg
    final leftHip = Offset(88 * scale, (115 - bobbing) * scale);
    final leftKnee = Offset(
      (88 + leftLegPhase * 20) * scale,
      (132 - leftLegPhase.clamp(-1.0, 0.0) * 8 - bobbing) * scale,
    );
    final leftFoot = Offset(
      (88 + leftLegPhase * 32) * scale,
      (150 + (leftLegPhase > 0 ? 0 : 6) - bobbing) * scale,
    );

    final leftLegPath = Path()
      ..moveTo(leftHip.dx, leftHip.dy)
      ..lineTo(leftKnee.dx, leftKnee.dy)
      ..lineTo(leftFoot.dx, leftFoot.dy);
    canvas.drawPath(leftLegPath, strokePaint);

    // Left Shoe
    final leftShoe = Path()
      ..moveTo(leftFoot.dx - 12 * scale, leftFoot.dy - 4 * scale)
      ..lineTo(leftFoot.dx + 16 * scale, leftFoot.dy - 4 * scale)
      ..lineTo(leftFoot.dx + 12 * scale, leftFoot.dy + 8 * scale)
      ..lineTo(leftFoot.dx - 14 * scale, leftFoot.dy + 8 * scale)
      ..close();
    canvas.drawPath(leftShoe, bodyPaint);
    canvas.drawPath(leftShoe, strokePaint);

    // Right Leg
    final rightHip = Offset(132 * scale, (115 - bobbing) * scale);
    final rightKnee = Offset(
      (132 + rightLegPhase * 20) * scale,
      (132 - rightLegPhase.clamp(-1.0, 0.0) * 8 - bobbing) * scale,
    );
    final rightFoot = Offset(
      (132 + rightLegPhase * 32) * scale,
      (150 + (rightLegPhase > 0 ? 0 : 6) - bobbing) * scale,
    );

    final rightLegPath = Path()
      ..moveTo(rightHip.dx, rightHip.dy)
      ..lineTo(rightKnee.dx, rightKnee.dy)
      ..lineTo(rightFoot.dx, rightFoot.dy);
    canvas.drawPath(rightLegPath, strokePaint);

    // Right Shoe
    final rightShoe = Path()
      ..moveTo(rightFoot.dx - 12 * scale, rightFoot.dy - 4 * scale)
      ..lineTo(rightFoot.dx + 16 * scale, rightFoot.dy - 4 * scale)
      ..lineTo(rightFoot.dx + 12 * scale, rightFoot.dy + 8 * scale)
      ..lineTo(rightFoot.dx - 14 * scale, rightFoot.dy + 8 * scale)
      ..close();
    canvas.drawPath(rightShoe, bodyPaint);
    canvas.drawPath(rightShoe, strokePaint);

    // ── ENVELOPE BODY (Forward Lean & Bounce) ──
    canvas.save();
    canvas.translate(110 * scale, (80 - bobbing) * scale);
    canvas.rotate(0.12); // Forward lean while sprinting
    canvas.translate(-110 * scale, -(80 - bobbing) * scale);

    final envRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(55 * scale, (40 - bobbing) * scale, 110 * scale, 75 * scale),
      Radius.circular(16 * scale),
    );
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    // Envelope Flaps
    final flapTop = Path()
      ..moveTo(57 * scale, (42 - bobbing) * scale)
      ..lineTo(110 * scale, (78 - bobbing) * scale)
      ..lineTo(163 * scale, (42 - bobbing) * scale);
    canvas.drawPath(flapTop, strokePaint);

    final flapBottom = Path()
      ..moveTo(57 * scale, (113 - bobbing) * scale)
      ..lineTo(98 * scale, (78 - bobbing) * scale);
    canvas.drawPath(flapBottom, strokePaint);

    final flapBottomRight = Path()
      ..moveTo(163 * scale, (113 - bobbing) * scale)
      ..lineTo(122 * scale, (78 - bobbing) * scale);
    canvas.drawPath(flapBottomRight, strokePaint);

    // Face (Excited Sprinting Eyes ^ ^ & Joyful Open Smile)
    final leftEye = Path()
      ..moveTo(88 * scale, (65 - bobbing) * scale)
      ..quadraticBezierTo(94 * scale, (58 - bobbing) * scale, 100 * scale, (65 - bobbing) * scale);
    canvas.drawPath(leftEye, strokePaint);

    final rightEye = Path()
      ..moveTo(120 * scale, (65 - bobbing) * scale)
      ..quadraticBezierTo(126 * scale, (58 - bobbing) * scale, 132 * scale, (65 - bobbing) * scale);
    canvas.drawPath(rightEye, strokePaint);

    final openSmile = Path()
      ..moveTo(102 * scale, (70 - bobbing) * scale)
      ..quadraticBezierTo(110 * scale, (82 - bobbing) * scale, 118 * scale, (70 - bobbing) * scale)
      ..close();
    canvas.drawPath(openSmile, Paint()..color = const Color(0xFF121214));

    // Rosy Blush
    canvas.drawOval(Rect.fromLTWH(84 * scale, (70 - bobbing) * scale, 10 * scale, 5 * scale), blushPaint);
    canvas.drawOval(Rect.fromLTWH(126 * scale, (70 - bobbing) * scale, 10 * scale, 5 * scale), blushPaint);

    // ── ARMS (Pumping Running Arms) ──
    // Left Arm (Pumping back)
    final leftArm = Path()
      ..moveTo(55 * scale, (72 - bobbing) * scale)
      ..lineTo((38 - leftLegPhase * 10) * scale, (62 + leftLegPhase * 8 - bobbing) * scale);
    canvas.drawPath(leftArm, strokePaint);
    canvas.drawCircle(Offset((38 - leftLegPhase * 10) * scale, (62 + leftLegPhase * 8 - bobbing) * scale), 7 * scale, bodyPaint);
    canvas.drawCircle(Offset((38 - leftLegPhase * 10) * scale, (62 + leftLegPhase * 8 - bobbing) * scale), 7 * scale, strokePaint);

    // Right Arm (Pumping forward)
    final rightArm = Path()
      ..moveTo(165 * scale, (72 - bobbing) * scale)
      ..lineTo((182 + rightLegPhase * 12) * scale, (62 - rightLegPhase * 10 - bobbing) * scale);
    canvas.drawPath(rightArm, strokePaint);
    canvas.drawCircle(Offset((182 + rightLegPhase * 12) * scale, (62 - rightLegPhase * 10 - bobbing) * scale), 7 * scale, bodyPaint);
    canvas.drawCircle(Offset((182 + rightLegPhase * 12) * scale, (62 - rightLegPhase * 10 - bobbing) * scale), 7 * scale, strokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RunningMascotPainter oldDelegate) =>
      oldDelegate.progress != progress;
}


// ============================================================================
// 2. CRYING ENVELOPE MASCOT (HOMEPAGE EMPTY STATE SAD / CRYING POSE)
// ============================================================================
class CryingEnvelopeMascot extends StatefulWidget {
  final double width;
  final double height;

  const CryingEnvelopeMascot({
    super.key,
    this.width = 220,
    this.height = 160,
  });

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
    final sob = (math.sin(progress * 4 * math.pi) * 2.5).abs() * scale;

    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tearPaint = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final puddlePaint = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // ── TEAR PUDDLE UNDERNEATH ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(110 * scale, 155 * scale), width: (50 + sob * 2) * scale, height: 12 * scale),
      puddlePaint,
    );

    // ── LEGS (Slumped / Drooping Sad Stance) ──
    canvas.drawLine(Offset(90 * scale, 120 * scale), Offset(85 * scale, 148 * scale), strokePaint);
    canvas.drawLine(Offset(130 * scale, 120 * scale), Offset(135 * scale, 148 * scale), strokePaint);

    // Shoes
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(70 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(70 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)),
      strokePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(126 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(126 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)),
      strokePaint,
    );

    // ── ENVELOPE BODY (Slightly slumped with sobbing pulsation) ──
    final envRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(55 * scale, (45 + sob) * scale, 110 * scale, 75 * scale),
      Radius.circular(16 * scale),
    );
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    // Flap
    final flapTop = Path()
      ..moveTo(57 * scale, (47 + sob) * scale)
      ..lineTo(110 * scale, (85 + sob) * scale)
      ..lineTo(163 * scale, (47 + sob) * scale);
    canvas.drawPath(flapTop, strokePaint);

    // Sad Eyes (Tears streaming down T_T)
    // Left eye (crying line / closed sad arc)
    final leftEye = Path()
      ..moveTo(84 * scale, (72 + sob) * scale)
      ..quadraticBezierTo(90 * scale, (78 + sob) * scale, 96 * scale, (72 + sob) * scale);
    canvas.drawPath(leftEye, strokePaint);

    // Right eye
    final rightEye = Path()
      ..moveTo(124 * scale, (72 + sob) * scale)
      ..quadraticBezierTo(130 * scale, (78 + sob) * scale, 136 * scale, (72 + sob) * scale);
    canvas.drawPath(rightEye, strokePaint);

    // Sad Quivering Mouth :'(
    final sadMouth = Path()
      ..moveTo(104 * scale, (88 + sob) * scale)
      ..quadraticBezierTo(110 * scale, (80 + sob) * scale, 116 * scale, (88 + sob) * scale);
    canvas.drawPath(sadMouth, strokePaint);

    // ── ANIMATED DRIPPING TEARS ──
    final tearPhase1 = (progress * 2) % 1.0;
    final tearPhase2 = ((progress + 0.5) * 2) % 1.0;

    // Left Tear Stream
    canvas.drawCircle(Offset(86 * scale, (76 + sob + tearPhase1 * 50) * scale), 4 * scale * (1 - tearPhase1 * 0.4), tearPaint);
    canvas.drawCircle(Offset(88 * scale, (76 + sob + tearPhase2 * 50) * scale), 3.5 * scale * (1 - tearPhase2 * 0.4), tearPaint);

    // Right Tear Stream
    canvas.drawCircle(Offset(134 * scale, (76 + sob + tearPhase1 * 50) * scale), 4 * scale * (1 - tearPhase1 * 0.4), tearPaint);
    canvas.drawCircle(Offset(132 * scale, (76 + sob + tearPhase2 * 50) * scale), 3.5 * scale * (1 - tearPhase2 * 0.4), tearPaint);

    // ── ARMS (Wiping tears / Holding head sadly) ──
    final leftArm = Path()
      ..moveTo(55 * scale, (78 + sob) * scale)
      ..cubicTo(45 * scale, (68 + sob) * scale, 68 * scale, (65 + sob) * scale, 78 * scale, (74 + sob) * scale);
    canvas.drawPath(leftArm, strokePaint);
    canvas.drawCircle(Offset(78 * scale, (74 + sob) * scale), 6 * scale, bodyPaint);
    canvas.drawCircle(Offset(78 * scale, (74 + sob) * scale), 6 * scale, strokePaint);

    final rightArm = Path()
      ..moveTo(165 * scale, (78 + sob) * scale)
      ..cubicTo(175 * scale, (68 + sob) * scale, 152 * scale, (65 + sob) * scale, 142 * scale, (74 + sob) * scale);
    canvas.drawPath(rightArm, strokePaint);
    canvas.drawCircle(Offset(142 * scale, (74 + sob) * scale), 6 * scale, bodyPaint);
    canvas.drawCircle(Offset(142 * scale, (74 + sob) * scale), 6 * scale, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CryingMascotPainter oldDelegate) =>
      oldDelegate.progress != progress;
}


// ============================================================================
// 3. PRO KING ENVELOPE MASCOT (ACTIVE ANIMATION: ROTATING STAR + GLEAM + ++++)
// ============================================================================
class ProKingEnvelopeMascot extends StatefulWidget {
  final double width;
  final double height;

  const ProKingEnvelopeMascot({
    super.key,
    this.width = 240,
    this.height = 180,
  });

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
      duration: const Duration(milliseconds: 2000),
    )..repeat();
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
          painter: _ProKingMascotPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ProKingMascotPainter extends CustomPainter {
  final double progress;

  _ProKingMascotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    final floatOffset = math.sin(progress * 2 * math.pi) * 4.0 * scale;

    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final goldFill = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // ── ANIMATED RETRO "+" SPARKLE ACCENTS (+ + + +) ──
    void drawPlus(Offset center, double s, Color color, double pulsePhase) {
      final pulse = 1.0 + 0.25 * math.sin((progress + pulsePhase) * 2 * math.pi);
      final pPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * scale * pulse
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx - s * scale * pulse, center.dy),
        Offset(center.dx + s * scale * pulse, center.dy),
        pPaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - s * scale * pulse),
        Offset(center.dx, center.dy + s * scale * pulse),
        pPaint,
      );
    }

    drawPlus(Offset(28 * scale, (35 + floatOffset * 0.5) * scale), 9, const Color(0xFFF59E0B), 0.0);
    drawPlus(Offset(50 * scale, (18 - floatOffset * 0.4) * scale), 5, const Color(0xFF5C44E4), 0.25);
    drawPlus(Offset(212 * scale, (32 - floatOffset * 0.5) * scale), 10, const Color(0xFFF59E0B), 0.5);
    drawPlus(Offset(188 * scale, (18 + floatOffset * 0.3) * scale), 6, const Color(0xFF1E8E3E), 0.75);
    drawPlus(Offset(22 * scale, (130 - floatOffset * 0.3) * scale), 7, const Color(0xFF5C44E4), 0.33);
    drawPlus(Offset(218 * scale, (125 + floatOffset * 0.4) * scale), 8, const Color(0xFFF59E0B), 0.66);

    // ── LEGS ──
    canvas.drawLine(Offset(85 * scale, 125 * scale), Offset(75 * scale, 155 * scale), strokePaint);
    canvas.drawLine(Offset(155 * scale, 125 * scale), Offset(165 * scale, 155 * scale), strokePaint);

    final leftShoe = Path()
      ..moveTo(60 * scale, 150 * scale)
      ..lineTo(90 * scale, 150 * scale)
      ..lineTo(85 * scale, 168 * scale)
      ..lineTo(52 * scale, 168 * scale)
      ..close();
    canvas.drawPath(leftShoe, bodyPaint);
    canvas.drawPath(leftShoe, strokePaint);

    final rightShoe = Path()
      ..moveTo(150 * scale, 150 * scale)
      ..lineTo(180 * scale, 150 * scale)
      ..lineTo(188 * scale, 168 * scale)
      ..lineTo(155 * scale, 168 * scale)
      ..close();
    canvas.drawPath(rightShoe, bodyPaint);
    canvas.drawPath(rightShoe, strokePaint);

    // ── MAIN BODY WITH FLOAT ──
    final envRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(55 * scale, (48 + floatOffset) * scale, 130 * scale, 82 * scale),
      Radius.circular(16 * scale),
    );
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    // Flap
    final flapTop = Path()
      ..moveTo(57 * scale, (50 + floatOffset) * scale)
      ..lineTo(120 * scale, (92 + floatOffset) * scale)
      ..lineTo(183 * scale, (50 + floatOffset) * scale);
    canvas.drawPath(flapTop, strokePaint);

    // ── GOLDEN CROWN ──
    final crownPath = Path()
      ..moveTo(95 * scale, (48 + floatOffset) * scale)
      ..lineTo(88 * scale, (22 + floatOffset) * scale)
      ..lineTo(108 * scale, (34 + floatOffset) * scale)
      ..lineTo(120 * scale, (14 + floatOffset) * scale)
      ..lineTo(132 * scale, (34 + floatOffset) * scale)
      ..lineTo(152 * scale, (22 + floatOffset) * scale)
      ..lineTo(145 * scale, (48 + floatOffset) * scale)
      ..close();
    canvas.drawPath(crownPath, goldFill);
    canvas.drawPath(crownPath, strokePaint);

    // Crown Jewel Gleam
    final gleamAlpha = 0.5 + 0.5 * math.sin(progress * 4 * math.pi);
    final gleamPaint = Paint()..color = Colors.white.withValues(alpha: gleamAlpha);
    canvas.drawCircle(Offset(120 * scale, (14 + floatOffset) * scale), 3.5 * scale, gleamPaint);

    // ── FACE ──
    final leftEye = Path()
      ..moveTo(92 * scale, (76 + floatOffset) * scale)
      ..quadraticBezierTo(98 * scale, (68 + floatOffset) * scale, 104 * scale, (76 + floatOffset) * scale);
    canvas.drawPath(leftEye, strokePaint);

    final rightEye = Path()
      ..moveTo(136 * scale, (76 + floatOffset) * scale)
      ..quadraticBezierTo(142 * scale, (68 + floatOffset) * scale, 148 * scale, (76 + floatOffset) * scale);
    canvas.drawPath(rightEye, strokePaint);

    final smile = Path()
      ..moveTo(112 * scale, (82 + floatOffset) * scale)
      ..quadraticBezierTo(120 * scale, (92 + floatOffset) * scale, 128 * scale, (82 + floatOffset) * scale);
    canvas.drawPath(smile, strokePaint);

    canvas.drawOval(Rect.fromLTWH(88 * scale, (80 + floatOffset) * scale, 12 * scale, 6 * scale), blushPaint);
    canvas.drawOval(Rect.fromLTWH(140 * scale, (80 + floatOffset) * scale, 12 * scale, 6 * scale), blushPaint);

    // ── ARMS & ROTATING STAR ──
    // Left Arm (Thumbs Up)
    final leftArm = Path()
      ..moveTo(55 * scale, (85 + floatOffset) * scale)
      ..cubicTo(32 * scale, (75 + floatOffset) * scale, 25 * scale, (55 + floatOffset) * scale, 35 * scale, (42 + floatOffset) * scale);
    canvas.drawPath(leftArm, strokePaint);
    canvas.drawCircle(Offset(35 * scale, (42 + floatOffset) * scale), 9 * scale, bodyPaint);
    canvas.drawCircle(Offset(35 * scale, (42 + floatOffset) * scale), 9 * scale, strokePaint);

    // Right Arm (Holding Rotating Star)
    final rightArm = Path()
      ..moveTo(185 * scale, (85 + floatOffset) * scale)
      ..cubicTo(208 * scale, (75 + floatOffset) * scale, 215 * scale, (55 + floatOffset) * scale, 205 * scale, (42 + floatOffset) * scale);
    canvas.drawPath(rightArm, strokePaint);
    canvas.drawCircle(Offset(205 * scale, (42 + floatOffset) * scale), 9 * scale, bodyPaint);
    canvas.drawCircle(Offset(205 * scale, (42 + floatOffset) * scale), 9 * scale, strokePaint);

    // Rotating Star
    final starCenter = Offset(205 * scale, (28 + floatOffset) * scale);
    final starRot = progress * 2 * math.pi;
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final a = starRot + (i * 72 - 18) * math.pi / 180;
      final x1 = starCenter.dx + 13.0 * scale * math.cos(a);
      final y1 = starCenter.dy + 13.0 * scale * math.sin(a);
      if (i == 0) {
        starPath.moveTo(x1, y1);
      } else {
        starPath.lineTo(x1, y1);
      }
      final na = a + 36 * math.pi / 180;
      final x2 = starCenter.dx + 6.0 * scale * math.cos(na);
      final y2 = starCenter.dy + 6.0 * scale * math.sin(na);
      starPath.lineTo(x2, y2);
    }
    starPath.close();
    canvas.drawPath(starPath, goldFill);
    canvas.drawPath(starPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ProKingMascotPainter oldDelegate) =>
      oldDelegate.progress != progress;
}


// ============================================================================
// 4. DISCOVERY EXPLORER MASCOT (MAGNIFYING GLASS SCANNER ANIMATION)
// ============================================================================
class DiscoveryExplorerMascot extends StatefulWidget {
  final double width;
  final double height;

  const DiscoveryExplorerMascot({
    super.key,
    this.width = 220,
    this.height = 160,
  });

  @override
  State<DiscoveryExplorerMascot> createState() => _DiscoveryExplorerMascotState();
}

class _DiscoveryExplorerMascotState extends State<DiscoveryExplorerMascot>
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
    final scale = size.width / 220.0;
    final scanOffset = math.sin(progress * 2 * math.pi) * 14.0 * scale;

    final bodyPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cyanFill = Paint()..color = const Color(0xFF00C7BE)..style = PaintingStyle.fill;

    // Legs
    canvas.drawLine(Offset(85 * scale, 120 * scale), Offset(78 * scale, 148 * scale), strokePaint);
    canvas.drawLine(Offset(135 * scale, 120 * scale), Offset(142 * scale, 148 * scale), strokePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), strokePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(132 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(132 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), strokePaint);

    // Body
    final envRect = RRect.fromRectAndRadius(Rect.fromLTWH(55 * scale, 45 * scale, 110 * scale, 75 * scale), Radius.circular(16 * scale));
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    // Flap
    final flapTop = Path()..moveTo(57 * scale, 47 * scale)..lineTo(110 * scale, 85 * scale)..lineTo(163 * scale, 47 * scale);
    canvas.drawPath(flapTop, strokePaint);

    // Wide curious eyes
    canvas.drawCircle(Offset(88 * scale, 72 * scale), 7 * scale, Paint()..color = const Color(0xFF121214));
    canvas.drawCircle(Offset(90 * scale, 70 * scale), 2.5 * scale, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(132 * scale, 72 * scale), 7 * scale, Paint()..color = const Color(0xFF121214));
    canvas.drawCircle(Offset(134 * scale, 70 * scale), 2.5 * scale, Paint()..color = Colors.white);

    // Smile
    final smile = Path()..moveTo(104 * scale, 82 * scale)..quadraticBezierTo(110 * scale, 90 * scale, 116 * scale, 82 * scale);
    canvas.drawPath(smile, strokePaint);

    // ── ANIMATED SCANNING MAGNIFYING GLASS ──
    final glassCenter = Offset((170 * scale) + scanOffset, 55 * scale);
    canvas.drawCircle(glassCenter, 20 * scale, cyanFill..color = const Color(0xFF00C7BE).withValues(alpha: 0.3));
    canvas.drawCircle(glassCenter, 20 * scale, strokePaint);
    canvas.drawLine(Offset(glassCenter.dx - 14 * scale, glassCenter.dy + 14 * scale), Offset(glassCenter.dx - 26 * scale, glassCenter.dy + 26 * scale), strokePaint..strokeWidth = 5 * scale);

    // Radar beam ripples
    final radarR = 24.0 * scale + (progress * 16 * scale);
    canvas.drawCircle(glassCenter, radarR, Paint()..color = const Color(0xFF00C7BE).withValues(alpha: (1 - progress) * 0.4)..style = PaintingStyle.stroke..strokeWidth = 2 * scale);
  }

  @override
  bool shouldRepaint(covariant _DiscoveryExplorerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}


// ============================================================================
// 5. TRACKER CLIPBOARD MASCOT (JOB LIST WELCOME SCREEN)
// ============================================================================
class TrackerClipboardMascot extends StatefulWidget {
  final double width;
  final double height;

  const TrackerClipboardMascot({
    super.key,
    this.width = 220,
    this.height = 160,
  });

  @override
  State<TrackerClipboardMascot> createState() => _TrackerClipboardMascotState();
}

class _TrackerClipboardMascotState extends State<TrackerClipboardMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
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
          painter: _TrackerClipboardPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _TrackerClipboardPainter extends CustomPainter {
  final double progress;

  _TrackerClipboardPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 220.0;
    final tapBob = math.sin(progress * 2 * math.pi) * 3.0 * scale;

    final bodyPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final greenFill = Paint()..color = const Color(0xFF1E8E3E)..style = PaintingStyle.fill;

    // Legs
    canvas.drawLine(Offset(85 * scale, 120 * scale), Offset(78 * scale, 148 * scale), strokePaint);
    canvas.drawLine(Offset(135 * scale, 120 * scale), Offset(142 * scale, 148 * scale), strokePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), strokePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(132 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(132 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), strokePaint);

    // Body
    final envRect = RRect.fromRectAndRadius(Rect.fromLTWH(55 * scale, (45 + tapBob) * scale, 110 * scale, 75 * scale), Radius.circular(16 * scale));
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    // Flap
    final flapTop = Path()..moveTo(57 * scale, (47 + tapBob) * scale)..lineTo(110 * scale, (85 + tapBob) * scale)..lineTo(163 * scale, (47 + tapBob) * scale);
    canvas.drawPath(flapTop, strokePaint);

    // Cheerful Eyes ^ ^
    final leftEye = Path()..moveTo(82 * scale, (72 + tapBob) * scale)..quadraticBezierTo(88 * scale, (64 + tapBob) * scale, 94 * scale, (72 + tapBob) * scale);
    canvas.drawPath(leftEye, strokePaint);

    final rightEye = Path()..moveTo(126 * scale, (72 + tapBob) * scale)..quadraticBezierTo(132 * scale, (64 + tapBob) * scale, 138 * scale, (72 + tapBob) * scale);
    canvas.drawPath(rightEye, strokePaint);

    // Smile
    final smile = Path()..moveTo(104 * scale, (82 + tapBob) * scale)..quadraticBezierTo(110 * scale, (90 + tapBob) * scale, 116 * scale, (82 + tapBob) * scale);
    canvas.drawPath(smile, strokePaint);

    // ── ANIMATED CLIPBOARD IN FRONT ──
    final clipRect = RRect.fromRectAndRadius(Rect.fromLTWH(150 * scale, (40 + tapBob) * scale, 45 * scale, 60 * scale), Radius.circular(8 * scale));
    canvas.drawRRect(clipRect, Paint()..color = const Color(0xFFF3EEFF));
    canvas.drawRRect(clipRect, strokePaint..strokeWidth = 2.4 * scale);

    // Clip top
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(162 * scale, (36 + tapBob) * scale, 20 * scale, 8 * scale), Radius.circular(4 * scale)), Paint()..color = const Color(0xFF19191B));

    // Checkmarks on clipboard (animated check)
    canvas.drawCircle(Offset(160 * scale, (52 + tapBob) * scale), 4 * scale, greenFill);
    canvas.drawLine(Offset(168 * scale, (52 + tapBob) * scale), Offset(186 * scale, (52 + tapBob) * scale), strokePaint..strokeWidth = 2 * scale);

    canvas.drawCircle(Offset(160 * scale, (65 + tapBob) * scale), 4 * scale, greenFill);
    canvas.drawLine(Offset(168 * scale, (65 + tapBob) * scale), Offset(186 * scale, (65 + tapBob) * scale), strokePaint..strokeWidth = 2 * scale);

    final check3Pulse = progress > 0.5;
    if (check3Pulse) {
      canvas.drawCircle(Offset(160 * scale, (78 + tapBob) * scale), 4 * scale, greenFill);
    }
    canvas.drawLine(Offset(168 * scale, (78 + tapBob) * scale), Offset(186 * scale, (78 + tapBob) * scale), strokePaint..strokeWidth = 2 * scale);
  }

  @override
  bool shouldRepaint(covariant _TrackerClipboardPainter oldDelegate) =>
      oldDelegate.progress != progress;
}


// ============================================================================
// 6. SCHOLAR PREP MASCOT (CAREER PREP WELCOME SCREEN)
// ============================================================================
class ScholarPrepMascot extends StatefulWidget {
  final double width;
  final double height;

  const ScholarPrepMascot({
    super.key,
    this.width = 220,
    this.height = 160,
  });

  @override
  State<ScholarPrepMascot> createState() => _ScholarPrepMascotState();
}

class _ScholarPrepMascotState extends State<ScholarPrepMascot>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _ScholarPrepPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ScholarPrepPainter extends CustomPainter {
  final double progress;

  _ScholarPrepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 220.0;
    final floatBob = math.sin(progress * 2 * math.pi) * 3.5 * scale;
    final tasselSway = math.sin(progress * 2 * math.pi) * 6.0 * scale;

    final bodyPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final togaBlack = Paint()..color = const Color(0xFF19191B)..style = PaintingStyle.fill;
    final goldTassel = Paint()..color = const Color(0xFFF59E0B)..style = PaintingStyle.fill;

    // Legs
    canvas.drawLine(Offset(85 * scale, 120 * scale), Offset(78 * scale, 148 * scale), strokePaint);
    canvas.drawLine(Offset(135 * scale, 120 * scale), Offset(142 * scale, 148 * scale), strokePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), strokePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(132 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(132 * scale, 144 * scale, 24 * scale, 10 * scale), Radius.circular(5 * scale)), strokePaint);

    // Body
    final envRect = RRect.fromRectAndRadius(Rect.fromLTWH(55 * scale, (45 + floatBob) * scale, 110 * scale, 75 * scale), Radius.circular(16 * scale));
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    // Flap
    final flapTop = Path()..moveTo(57 * scale, (47 + floatBob) * scale)..lineTo(110 * scale, (85 + floatBob) * scale)..lineTo(163 * scale, (47 + floatBob) * scale);
    canvas.drawPath(flapTop, strokePaint);

    // ── GRADUATION CAP (TOGA) ON TOP ──
    final capPath = Path()
      ..moveTo(110 * scale, (20 + floatBob) * scale)
      ..lineTo(155 * scale, (35 + floatBob) * scale)
      ..lineTo(110 * scale, (48 + floatBob) * scale)
      ..lineTo(65 * scale, (35 + floatBob) * scale)
      ..close();
    canvas.drawPath(capPath, togaBlack);
    canvas.drawPath(capPath, strokePaint..strokeWidth = 2.4 * scale);

    // Cap base
    final capBase = Path()
      ..moveTo(88 * scale, (40 + floatBob) * scale)
      ..lineTo(88 * scale, (48 + floatBob) * scale)
      ..quadraticBezierTo(110 * scale, (54 + floatBob) * scale, 132 * scale, (48 + floatBob) * scale)
      ..lineTo(132 * scale, (40 + floatBob) * scale);
    canvas.drawPath(capBase, togaBlack);
    canvas.drawPath(capBase, strokePaint);

    // Tassel hanging & swaying
    final tasselPath = Path()
      ..moveTo(110 * scale, (34 + floatBob) * scale)
      ..lineTo((148 * scale) + tasselSway, (48 + floatBob) * scale);
    canvas.drawPath(tasselPath, strokePaint..strokeWidth = 2.0 * scale);
    canvas.drawCircle(Offset((148 * scale) + tasselSway, (50 + floatBob) * scale), 3.5 * scale, goldTassel);

    // Eyes with scholarly glasses
    canvas.drawCircle(Offset(88 * scale, (72 + floatBob) * scale), 10 * scale, bodyPaint);
    canvas.drawCircle(Offset(88 * scale, (72 + floatBob) * scale), 10 * scale, strokePaint..strokeWidth = 2.2 * scale);
    canvas.drawCircle(Offset(132 * scale, (72 + floatBob) * scale), 10 * scale, bodyPaint);
    canvas.drawCircle(Offset(132 * scale, (72 + floatBob) * scale), 10 * scale, strokePaint..strokeWidth = 2.2 * scale);
    canvas.drawLine(Offset(98 * scale, (72 + floatBob) * scale), Offset(122 * scale, (72 + floatBob) * scale), strokePaint);

    // Smile
    final smile = Path()..moveTo(104 * scale, (84 + floatBob) * scale)..quadraticBezierTo(110 * scale, (92 + floatBob) * scale, 116 * scale, (84 + floatBob) * scale);
    canvas.drawPath(smile, strokePaint..strokeWidth = 3.2 * scale);
  }

  @override
  bool shouldRepaint(covariant _ScholarPrepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
