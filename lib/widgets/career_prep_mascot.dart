import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Career Prep Mascot with Graduation Cap, Book & Swaying Tassel.
class CareerPrepMascot extends StatefulWidget {
  final double width;
  final double height;

  const CareerPrepMascot({
    super.key,
    this.width = 240,
    this.height = 180,
  });

  @override
  State<CareerPrepMascot> createState() => _CareerPrepMascotState();
}

class _CareerPrepMascotState extends State<CareerPrepMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
          painter: _CareerPrepPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _CareerPrepPainter extends CustomPainter {
  final double progress;

  _CareerPrepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    final t = progress * 2 * math.pi;

    final bodyPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final blackFill = Paint()..color = const Color(0xFF121214)..style = PaintingStyle.fill;
    final bobY = math.sin(t) * 5 * scale;
    final tasselSway = math.sin(t) * 8 * scale;

    // Legs
    final leftLeg = Path()..moveTo(85 * scale, 125 * scale)..lineTo(75 * scale, 155 * scale);
    canvas.drawPath(leftLeg, strokePaint);
    final leftShoe = Path()..moveTo(58 * scale, 150 * scale)..lineTo(88 * scale, 150 * scale)..lineTo(84 * scale, 166 * scale)..lineTo(52 * scale, 166 * scale)..close();
    canvas.drawPath(leftShoe, bodyPaint);
    canvas.drawPath(leftShoe, strokePaint);

    final rightLeg = Path()..moveTo(155 * scale, 125 * scale)..lineTo(165 * scale, 155 * scale);
    canvas.drawPath(rightLeg, strokePaint);
    final rightShoe = Path()..moveTo(150 * scale, 150 * scale)..lineTo(180 * scale, 150 * scale)..lineTo(188 * scale, 166 * scale)..lineTo(156 * scale, 166 * scale)..close();
    canvas.drawPath(rightShoe, bodyPaint);
    canvas.drawPath(rightShoe, strokePaint);

    // Body
    canvas.save();
    canvas.translate(0, bobY);

    // Main Envelope Body
    final envRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(55 * scale, 52 * scale, 130 * scale, 80 * scale),
      Radius.circular(16 * scale),
    );
    canvas.drawRRect(envRect, bodyPaint);
    canvas.drawRRect(envRect, strokePaint);

    final flapTop = Path()..moveTo(57 * scale, 54 * scale)..lineTo(120 * scale, 94 * scale)..lineTo(183 * scale, 54 * scale);
    canvas.drawPath(flapTop, strokePaint);

    // Graduation Mortarboard Cap on Head
    final capDiamond = Path()
      ..moveTo(120 * scale, 22 * scale)
      ..lineTo(168 * scale, 36 * scale)
      ..lineTo(120 * scale, 48 * scale)
      ..lineTo(72 * scale, 36 * scale)
      ..close();
    canvas.drawPath(capDiamond, blackFill);
    canvas.drawPath(capDiamond, strokePaint);

    final capBase = Path()
      ..moveTo(95 * scale, 42 * scale)
      ..lineTo(95 * scale, 52 * scale)
      ..quadraticBezierTo(120 * scale, 58 * scale, 145 * scale, 52 * scale)
      ..lineTo(145 * scale, 42 * scale);
    canvas.drawPath(capBase, blackFill);
    canvas.drawPath(capBase, strokePaint);

    // Golden Tassel (Swaying)
    final tasselPaint = Paint()..color = const Color(0xFFF59E0B)..strokeWidth = 2.8 * scale..strokeCap = StrokeCap.round;
    final tasselEnd = Offset((78 + tasselSway) * scale, 54 * scale);
    canvas.drawLine(Offset(120 * scale, 35 * scale), tasselEnd, tasselPaint);
    canvas.drawCircle(tasselEnd, 3.5 * scale, Paint()..color = const Color(0xFFF59E0B));

    // Smart Smiling Eyes with Glasses
    final glassRim = Paint()..color = const Color(0xFF5C44E4)..style = PaintingStyle.stroke..strokeWidth = 2.4 * scale;
    canvas.drawCircle(Offset(102 * scale, 76 * scale), 9 * scale, glassRim);
    canvas.drawCircle(Offset(138 * scale, 76 * scale), 9 * scale, glassRim);
    canvas.drawLine(Offset(111 * scale, 76 * scale), Offset(129 * scale, 76 * scale), glassRim);

    // Pupils
    canvas.drawCircle(Offset(102 * scale, 76 * scale), 3.5 * scale, blackFill);
    canvas.drawCircle(Offset(138 * scale, 76 * scale), 3.5 * scale, blackFill);

    // Confident Smile
    final smile = Path()..moveTo(112 * scale, 86 * scale)..quadraticBezierTo(120 * scale, 94 * scale, 128 * scale, 86 * scale);
    canvas.drawPath(smile, strokePaint);

    // Book in Arm
    final bookRect = RRect.fromRectAndRadius(Rect.fromLTWH(170 * scale, 75 * scale, 34 * scale, 42 * scale), Radius.circular(6 * scale));
    canvas.drawRRect(bookRect, Paint()..color = const Color(0xFF5C44E4));
    canvas.drawRRect(bookRect, strokePaint);
    canvas.drawLine(Offset(176 * scale, 82 * scale), Offset(198 * scale, 82 * scale), Paint()..color = Colors.white..strokeWidth = 2 * scale);
    canvas.drawLine(Offset(176 * scale, 90 * scale), Offset(196 * scale, 90 * scale), Paint()..color = Colors.white..strokeWidth = 2 * scale);

    // Left Hand (Waving)
    final waveArm = Path()..moveTo(55 * scale, 85 * scale)..cubicTo(35 * scale, 70 * scale, 26 * scale, 55 * scale, 34 * scale, 40 * scale);
    canvas.drawPath(waveArm, strokePaint);
    canvas.drawCircle(Offset(34 * scale, 40 * scale), 8 * scale, bodyPaint);
    canvas.drawCircle(Offset(34 * scale, 40 * scale), 8 * scale, strokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CareerPrepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
