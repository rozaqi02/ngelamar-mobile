import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Friendly envelope mascot resting at the bottom of the Calendar screen:
/// it holds a tiny calendar board in one hand and scribbles a note with a
/// pencil in the other. 100% vector artwork (GR-06) and the idle motion
/// honours reduced-motion settings.
class CalendarPlannerMascot extends StatefulWidget {
  final double width;
  final double height;
  final bool animate;

  const CalendarPlannerMascot({
    super.key,
    this.width = 190,
    this.height = 158,
    this.animate = true,
  });

  @override
  State<CalendarPlannerMascot> createState() => _CalendarPlannerMascotState();
}

class _CalendarPlannerMascotState extends State<CalendarPlannerMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant CalendarPlannerMascot oldWidget) {
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
        painter: _CalendarPlannerPainter(progress: 0),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _CalendarPlannerPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _CalendarPlannerPainter extends CustomPainter {
  final double progress;

  _CalendarPlannerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240;
    final t = progress * 2 * math.pi;
    final floatY = math.sin(t) * 2.4;
    final scribble = math.sin(t * 3) * 2.2;

    canvas.save();
    canvas.scale(scale);

    // Grounded oval shadow under the shoes — does not bob with idle float.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(120, 184), width: 118, height: 20),
      Paint()
        ..color = const Color(0xFF19191B).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    final ink = const Color(0xFF19191B);
    final outline = Paint()
      ..color = ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final bodyCenter = Offset(120, 96 + floatY);

    // ── Legs & shoes ──
    canvas.drawLine(
      Offset(bodyCenter.dx - 25, bodyCenter.dy + 36),
      const Offset(92, 172),
      outline,
    );
    canvas.drawLine(
      Offset(bodyCenter.dx + 25, bodyCenter.dy + 36),
      const Offset(148, 172),
      outline,
    );
    final shoe = Paint()..color = ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(89, 174), width: 24, height: 10),
        const Radius.circular(5),
      ),
      shoe,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(151, 174), width: 24, height: 10),
        const Radius.circular(5),
      ),
      shoe,
    );

    // ── Left arm holding a mini calendar board ──
    final leftHand = Offset(56, 112 + floatY * 0.6);
    canvas.drawLine(
      Offset(bodyCenter.dx - 55, bodyCenter.dy + 4),
      leftHand,
      outline,
    );

    final boardTopLeft = Offset(12, 66 + floatY * 0.6);
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(boardTopLeft.dx, boardTopLeft.dy, 62, 52),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      board,
      Paint()
        ..color = const Color(0xFF5C44E4).withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(board, Paint()..color = const Color(0xFFFFFEFB));
    canvas.drawRRect(board, outline..strokeWidth = 3);
    // Calendar header strip
    final headerStrip = RRect.fromRectAndRadius(
      Rect.fromLTWH(boardTopLeft.dx, boardTopLeft.dy, 62, 15),
      const Radius.circular(8),
    );
    canvas.drawRRect(headerStrip, Paint()..color = const Color(0xFF8B5CF6));
    canvas.drawLine(
      Offset(boardTopLeft.dx, boardTopLeft.dy + 15),
      Offset(boardTopLeft.dx + 62, boardTopLeft.dy + 15),
      outline..strokeWidth = 2.5,
    );
    // Binder rings
    canvas.drawLine(
      Offset(boardTopLeft.dx + 14, boardTopLeft.dy - 4),
      Offset(boardTopLeft.dx + 14, boardTopLeft.dy + 5),
      outline,
    );
    canvas.drawLine(
      Offset(boardTopLeft.dx + 48, boardTopLeft.dy - 4),
      Offset(boardTopLeft.dx + 48, boardTopLeft.dy + 5),
      outline,
    );
    // Calendar day dots + marked day
    final dotPaint = Paint()..color = const Color(0xFFC9C2D9);
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 4; col++) {
        canvas.drawCircle(
          Offset(
            boardTopLeft.dx + 12 + col * 13,
            boardTopLeft.dy + 27 + row * 13,
          ),
          3.2,
          dotPaint,
        );
      }
    }
    canvas.drawCircle(
      Offset(boardTopLeft.dx + 12 + 2 * 13, boardTopLeft.dy + 27),
      5.2,
      Paint()..color = const Color(0xFFFB7185),
    );
    canvas.drawCircle(
      Offset(boardTopLeft.dx + 12 + 2 * 13, boardTopLeft.dy + 27),
      5.2,
      outline..strokeWidth = 2.5,
    );

    // Left glove over the board edge
    canvas.drawCircle(leftHand, 6, Paint()..color = const Color(0xFFFFFEFB));
    canvas.drawCircle(leftHand, 6, outline..strokeWidth = 3);

    // ── Right arm scribbling a note with a pencil ──
    final pencilTip = Offset(206, 148 + floatY * 0.4 + scribble * 0.4);
    final rightHand = Offset(pencilTip.dx - 9, pencilTip.dy - 9);
    canvas.drawLine(
      Offset(bodyCenter.dx + 55, bodyCenter.dy + 4),
      rightHand,
      outline,
    );
    canvas.drawCircle(rightHand, 6, Paint()..color = const Color(0xFFFFFEFB));
    canvas.drawCircle(rightHand, 6, outline..strokeWidth = 3);

    // Note sheet
    final note = RRect.fromRectAndRadius(
      Rect.fromLTWH(168, 146 + floatY * 0.4, 58, 34),
      const Radius.circular(6),
    );
    canvas.drawRRect(note, Paint()..color = const Color(0xFFFFFEFB));
    canvas.drawRRect(note, outline..strokeWidth = 3);
    final linePaint = Paint()
      ..color = const Color(0xFFB9C2D0)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(176, 156 + floatY * 0.4),
      Offset(196 + scribble, 156 + floatY * 0.4),
      linePaint,
    );
    canvas.drawLine(
      Offset(176, 164 + floatY * 0.4),
      Offset(190 - scribble, 164 + floatY * 0.4),
      linePaint,
    );

    // Pencil
    final pencilBody = Paint()..color = const Color(0xFFFBBF24);
    final pencilPath = Path()
      ..moveTo(rightHand.dx + 2, rightHand.dy + 2)
      ..lineTo(pencilTip.dx, pencilTip.dy)
      ..lineTo(pencilTip.dx + 4, pencilTip.dy - 4)
      ..lineTo(rightHand.dx + 6, rightHand.dy - 2)
      ..close();
    canvas.drawPath(pencilPath, pencilBody);
    canvas.drawPath(pencilPath, outline..strokeWidth = 2.5);
    canvas.drawCircle(pencilTip, 2.4, Paint()..color = ink);

    // ── Envelope body ──
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bodyCenter, width: 118, height: 78),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFF5C44E4).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFFFFFEFB));
    canvas.drawRRect(bodyRect, outline..strokeWidth = 4);

    // Flap fold
    final fold = Path()
      ..moveTo(bodyCenter.dx - 57, bodyCenter.dy - 37)
      ..lineTo(bodyCenter.dx, bodyCenter.dy + 7)
      ..lineTo(bodyCenter.dx + 57, bodyCenter.dy - 37);
    canvas.drawPath(
      fold,
      Paint()
        ..color = const Color(0xFFD8D2C8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // ── Focused face looking at the note ──
    final face = Paint()
      ..color = ink
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final eyePaint = Paint()..color = ink;
    final leftEye = Offset(bodyCenter.dx - 20, bodyCenter.dy - 8);
    final rightEye = Offset(bodyCenter.dx + 20, bodyCenter.dy - 8);
    canvas.drawCircle(leftEye, 4.4, eyePaint);
    canvas.drawCircle(rightEye, 4.4, eyePaint);
    canvas.drawCircle(
      leftEye.translate(-1.4, -1.4),
      1.5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      rightEye.translate(-1.4, -1.4),
      1.5,
      Paint()..color = Colors.white,
    );

    // Rosy cheeks
    final blush = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyCenter.dx - 33, bodyCenter.dy + 5),
        width: 11,
        height: 6,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyCenter.dx + 33, bodyCenter.dy + 5),
        width: 11,
        height: 6,
      ),
      blush,
    );

    // Gentle content smile
    canvas.drawPath(
      Path()
        ..moveTo(bodyCenter.dx - 8, bodyCenter.dy + 11)
        ..quadraticBezierTo(
          bodyCenter.dx,
          bodyCenter.dy + 18,
          bodyCenter.dx + 8,
          bodyCenter.dy + 11,
        ),
      face,
    );

    // Tiny sparkle near the calendar board
    final sparklePaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    final sparkleCenter = Offset(86, 52 + floatY * 0.6 - scribble * 0.3);
    final sparklePath = Path()
      ..moveTo(sparkleCenter.dx, sparkleCenter.dy - 5)
      ..quadraticBezierTo(
        sparkleCenter.dx,
        sparkleCenter.dy,
        sparkleCenter.dx + 5,
        sparkleCenter.dy,
      )
      ..quadraticBezierTo(
        sparkleCenter.dx,
        sparkleCenter.dy,
        sparkleCenter.dx,
        sparkleCenter.dy + 5,
      )
      ..quadraticBezierTo(
        sparkleCenter.dx,
        sparkleCenter.dy,
        sparkleCenter.dx - 5,
        sparkleCenter.dy,
      )
      ..quadraticBezierTo(
        sparkleCenter.dx,
        sparkleCenter.dy,
        sparkleCenter.dx,
        sparkleCenter.dy - 5,
      )
      ..close();
    canvas.drawPath(sparklePath, sparklePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CalendarPlannerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
