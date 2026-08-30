import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bookmark reward mascot: the envelope jumps up from the bottom edge,
/// raises a confident thumbs-up, then lands back below the screen.
/// Pure vector artwork (GR-06); motion honours reduced-motion settings.
class BookmarkThumbsUpMascot extends StatefulWidget {
  final VoidCallback onComplete;

  const BookmarkThumbsUpMascot({super.key, required this.onComplete});

  static void show(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BookmarkThumbsUpMascot(onComplete: entry.remove),
    );
    overlay.insert(entry);
  }

  @override
  State<BookmarkThumbsUpMascot> createState() => _BookmarkThumbsUpMascotState();
}

class _BookmarkThumbsUpMascotState extends State<BookmarkThumbsUpMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return LayoutBuilder(
            builder: (context, constraints) {
              // Jump trajectory: rise from below, hold, land back below.
              final travel = constraints.maxHeight * 0.72;
              final double jumpY;
              if (t < 0.30) {
                final enter = Curves.easeOutBack.transform(
                  (t / 0.30).clamp(0.0, 1.0),
                );
                jumpY = travel * (1 - enter);
              } else if (t > 0.74) {
                final exit = Curves.easeInCubic.transform(
                  ((t - 0.74) / 0.26).clamp(0.0, 1.0),
                );
                jumpY = travel * exit;
              } else {
                jumpY = 0;
              }
              final bob = math.sin(t * math.pi * 6) * 3;

              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  // Resting spot sits around the lower third of the screen,
                  // not glued to the bottom edge.
                  padding: EdgeInsets.only(
                    bottom: constraints.maxHeight * 0.22 + bottomInset,
                  ),
                  child: Transform.translate(
                    offset: Offset(0, jumpY + bob),
                    child: CustomPaint(
                      size: const Size(150, 132),
                      painter: _ThumbsUpMascotPainter(progress: t),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ThumbsUpMascotPainter extends CustomPainter {
  final double progress;

  const _ThumbsUpMascotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200;
    // Thumbs-up pops right after the jump lands.
    final thumbUp = Curves.easeOutBack.transform(
      ((progress - 0.32) / 0.20).clamp(0.0, 1.0),
    );
    final thumbDown = Curves.easeInCubic.transform(
      ((progress - 0.72) / 0.16).clamp(0.0, 1.0),
    );
    final thumb = (thumbUp * (1 - thumbDown)).clamp(0.0, 1.0);
    final beat = math.sin(progress * math.pi * 6);

    canvas.save();
    canvas.scale(scale);

    final ink = const Color(0xFF19191B);
    final outline = Paint()
      ..color = ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    const bodyCenter = Offset(100, 72);

    // Legs
    final shoe = Paint()..color = ink;
    canvas.drawLine(const Offset(75, 108), const Offset(63, 128), outline);
    canvas.drawLine(const Offset(125, 108), const Offset(137, 128), outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(61, 129), width: 20, height: 9),
        const Radius.circular(4.5),
      ),
      shoe,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(139, 129), width: 20, height: 9),
        const Radius.circular(4.5),
      ),
      shoe,
    );

    // Left arm relaxed, right arm raises the thumb.
    final leftHand = const Offset(38, 84);
    canvas.drawLine(const Offset(43, 78), leftHand, outline);
    canvas.drawCircle(leftHand, 6, Paint()..color = const Color(0xFFFFFEFB));
    canvas.drawCircle(leftHand, 6, outline..strokeWidth = 3);

    final rightShoulder = const Offset(157, 78);
    final rightHand = Offset(
      172 - (1 - thumb) * 6,
      88 - thumb * 46 + beat * thumb * 1.5,
    );
    canvas.drawLine(rightShoulder, rightHand, outline);

    // Envelope body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bodyCenter, width: 116, height: 76),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFF5C44E4).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFFFFFEFB));
    canvas.drawRRect(bodyRect, outline);

    // Flap fold
    final fold = Path()
      ..moveTo(bodyCenter.dx - 56, bodyCenter.dy - 36)
      ..lineTo(bodyCenter.dx, bodyCenter.dy + 6)
      ..lineTo(bodyCenter.dx + 56, bodyCenter.dy - 36);
    canvas.drawPath(
      fold,
      Paint()
        ..color = const Color(0xFFD8D2C8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Joyful closed eyes
    final face = Paint()
      ..color = ink
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leftEye = Offset(bodyCenter.dx - 21, bodyCenter.dy - 8);
    final rightEye = Offset(bodyCenter.dx + 21, bodyCenter.dy - 8);
    canvas.drawPath(
      Path()
        ..moveTo(leftEye.dx - 6, leftEye.dy + 2)
        ..quadraticBezierTo(
          leftEye.dx,
          leftEye.dy - 6,
          leftEye.dx + 6,
          leftEye.dy + 2,
        ),
      face,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rightEye.dx - 6, rightEye.dy + 2)
        ..quadraticBezierTo(
          rightEye.dx,
          rightEye.dy - 6,
          rightEye.dx + 6,
          rightEye.dy + 2,
        ),
      face,
    );

    // Rosy cheeks
    final blush = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.65);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyCenter.dx - 33, bodyCenter.dy + 6),
        width: 11,
        height: 6,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyCenter.dx + 33, bodyCenter.dy + 6),
        width: 11,
        height: 6,
      ),
      blush,
    );

    // Big proud smile
    canvas.drawPath(
      Path()
        ..moveTo(bodyCenter.dx - 11, bodyCenter.dy + 12)
        ..quadraticBezierTo(
          bodyCenter.dx,
          bodyCenter.dy + 24 + beat.abs(),
          bodyCenter.dx + 11,
          bodyCenter.dy + 12,
        ),
      face,
    );

    // Thumbs-up glove on the right hand
    if (thumb > 0.02) {
      canvas.save();
      canvas.translate(rightHand.dx, rightHand.dy);
      canvas.scale(0.4 + thumb * 0.6);
      final gloveFill = Paint()..color = const Color(0xFFFFFEFB);
      final fist = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -4, 20, 17),
        const Radius.circular(7),
      );
      canvas.drawRRect(fist, gloveFill);
      canvas.drawRRect(fist, outline..strokeWidth = 3.5);
      final thumbPath = Path()
        ..moveTo(3, -3)
        ..quadraticBezierTo(1, -15, 8, -14)
        ..quadraticBezierTo(14, -13, 12, -3)
        ..close();
      canvas.drawPath(thumbPath, gloveFill);
      canvas.drawPath(thumbPath, outline..strokeWidth = 3.5);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThumbsUpMascotPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
