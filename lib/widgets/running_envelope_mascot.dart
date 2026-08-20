import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pixel-perfect vector rendering of the retro running envelope mascot
/// seen in the reference landing screen design.
class RunningEnvelopeMascot extends StatelessWidget {
  final double width;
  final double height;

  const RunningEnvelopeMascot({
    super.key,
    this.width = 240,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _EnvelopeMascotPainter(),
    );
  }
}

class _EnvelopeMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;

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

    // ── 1. BACK LEG & SHOE ──
    final backLegPath = Path()
      ..moveTo(65 * scale, 105 * scale)
      ..cubicTo(45 * scale, 125 * scale, 35 * scale, 140 * scale, 38 * scale, 152 * scale);
    canvas.drawPath(backLegPath, strokePaint);

    // Back Shoe
    final backShoe = Path()
      ..moveTo(38 * scale, 142 * scale)
      ..lineTo(52 * scale, 150 * scale)
      ..lineTo(42 * scale, 168 * scale)
      ..lineTo(22 * scale, 158 * scale)
      ..close();
    canvas.drawPath(backShoe, bodyPaint);
    canvas.drawPath(backShoe, strokePaint);

    // Back shoe sole line
    canvas.drawLine(
      Offset(26 * scale, 163 * scale),
      Offset(44 * scale, 163 * scale),
      strokePaint,
    );

    // ── 2. FRONT LEG & SHOE ──
    final frontLegPath = Path()
      ..moveTo(135 * scale, 105 * scale)
      ..cubicTo(165 * scale, 108 * scale, 185 * scale, 115 * scale, 195 * scale, 125 * scale);
    canvas.drawPath(frontLegPath, strokePaint);

    // Front Shoe
    final frontShoe = Path()
      ..moveTo(185 * scale, 115 * scale)
      ..lineTo(215 * scale, 128 * scale)
      ..lineTo(205 * scale, 148 * scale)
      ..lineTo(175 * scale, 136 * scale)
      ..close();
    canvas.drawPath(frontShoe, bodyPaint);
    canvas.drawPath(frontShoe, strokePaint);

    // Front shoe sole
    canvas.drawLine(
      Offset(180 * scale, 142 * scale),
      Offset(208 * scale, 138 * scale),
      strokePaint,
    );

    // ── 3. LEFT ARM (Back Arm swinging) ──
    final leftArm = Path()
      ..moveTo(68 * scale, 75 * scale)
      ..cubicTo(45 * scale, 65 * scale, 32 * scale, 70 * scale, 30 * scale, 82 * scale);
    canvas.drawPath(leftArm, strokePaint);

    // Left Fist/Hand
    final leftHand = Path()
      ..addOval(Rect.fromCircle(center: Offset(30 * scale, 82 * scale), radius: 10 * scale));
    canvas.drawPath(leftHand, bodyPaint);
    canvas.drawPath(leftHand, strokePaint);

    // ── 4. ENVELOPE BODY ──
    final envRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(58 * scale, 48 * scale, 124 * scale, 78 * scale),
      Radius.circular(16 * scale),
    );
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    // Envelope Bottom Flap V-Line
    final flapPath = Path()
      ..moveTo(60 * scale, 58 * scale)
      ..lineTo(120 * scale, 98 * scale)
      ..lineTo(180 * scale, 58 * scale);
    canvas.drawPath(flapPath, strokePaint);

    // ── 5. RIGHT ARM (Front Arm Punching Up!) ──
    final rightArm = Path()
      ..moveTo(160 * scale, 72 * scale)
      ..cubicTo(195 * scale, 65 * scale, 210 * scale, 50 * scale, 218 * scale, 38 * scale);
    canvas.drawPath(rightArm, strokePaint);

    // Right Fist
    final rightFist = Path()
      ..addOval(Rect.fromCircle(center: Offset(218 * scale, 38 * scale), radius: 12 * scale));
    canvas.drawPath(rightFist, bodyPaint);
    canvas.drawPath(rightFist, strokePaint);

    // Fist finger lines
    canvas.drawLine(
      Offset(212 * scale, 34 * scale),
      Offset(222 * scale, 34 * scale),
      strokePaint..strokeWidth = 2.2 * scale,
    );
    strokePaint.strokeWidth = 3.2 * scale; // restore

    // ── 6. BIG CARTOON GOOGLY EYES ──
    // Left Eye
    final leftEyeRect = Rect.fromCircle(center: Offset(120 * scale, 38 * scale), radius: 15 * scale);
    canvas.drawOval(leftEyeRect, bodyPaint);
    canvas.drawOval(leftEyeRect, strokePaint);

    // Left Pupil
    canvas.drawOval(
      Rect.fromCircle(center: Offset(124 * scale, 38 * scale), radius: 6 * scale),
      blackFill,
    );

    // Right Eye
    final rightEyeRect = Rect.fromCircle(center: Offset(148 * scale, 38 * scale), radius: 15 * scale);
    canvas.drawOval(rightEyeRect, bodyPaint);
    canvas.drawOval(rightEyeRect, strokePaint);

    // Right Pupil
    canvas.drawOval(
      Rect.fromCircle(center: Offset(152 * scale, 38 * scale), radius: 6 * scale),
      blackFill,
    );

    // ── 7. BIG TOOTHY GRIN MOUTH ──
    final mouthPath = Path()
      ..moveTo(105 * scale, 55 * scale)
      ..quadraticBezierTo(124 * scale, 75 * scale, 142 * scale, 55 * scale)
      ..quadraticBezierTo(124 * scale, 48 * scale, 105 * scale, 55 * scale);

    canvas.drawPath(mouthPath, bodyPaint);
    canvas.drawPath(mouthPath, strokePaint);

    // Mouth smile teeth grid lines
    canvas.drawLine(
      Offset(116 * scale, 52 * scale),
      Offset(116 * scale, 68 * scale),
      strokePaint..strokeWidth = 1.8 * scale,
    );
    canvas.drawLine(
      Offset(124 * scale, 51 * scale),
      Offset(124 * scale, 70 * scale),
      strokePaint,
    );
    canvas.drawLine(
      Offset(132 * scale, 52 * scale),
      Offset(132 * scale, 68 * scale),
      strokePaint,
    );
    strokePaint.strokeWidth = 3.2 * scale; // restore
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
