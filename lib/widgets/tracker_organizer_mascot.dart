import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Authentic Tracker / Organizer Envelope Mascot for "Daftar Lamaran".
/// Pose yang berbeda dan unik:
/// - Berdiri tegak & ceria dengan kaki kartun yang imut
/// - Tangan kiri memegang map berkas lamaran / CV dengan centang hijau
/// - Tangan kanan melambai memberikan jempol semangat (Thumbs Up)
/// - Animasi pernapasan & floating bounce yang lembut dan organik
class TrackerOrganizerMascot extends StatefulWidget {
  final double width;
  final double height;
  final bool animate;

  const TrackerOrganizerMascot({
    super.key,
    this.width = 250,
    this.height = 190,
    this.animate = true,
  });

  @override
  State<TrackerOrganizerMascot> createState() => _TrackerOrganizerMascotState();
}

class _TrackerOrganizerMascotState extends State<TrackerOrganizerMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TrackerOrganizerMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
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
          painter: _TrackerOrganizerMascotPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _TrackerOrganizerMascotPainter extends CustomPainter {
  final double progress;

  _TrackerOrganizerMascotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    final t = progress * math.pi;

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

    final greenFill = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final purpleFill = Paint()
      ..color = const Color(0xFF5C44E4)
      ..style = PaintingStyle.fill;

    // Gentle vertical bobbing & slight tilt
    final bodyBob = -math.sin(t) * 6.0 * scale;
    final waveArm = math.sin(t * 2) * 0.15;

    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.52 + bodyBob);

    // ── 1. SHADOW ON GROUND ──
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 72 * scale - bodyBob * 0.6),
        width: 120 * scale,
        height: 16 * scale,
      ),
      shadowPaint,
    );

    // ── 2. TWO STANDING LEGS & SNEAKERS ──
    // Left Leg
    final leftLegPath = Path()
      ..moveTo(-22 * scale, 34 * scale)
      ..lineTo(-26 * scale, 62 * scale);
    canvas.drawPath(leftLegPath, strokePaint);

    // Left Shoe
    final leftShoe = RRect.fromRectAndRadius(
      Rect.fromLTWH(-36 * scale, 60 * scale, 24 * scale, 12 * scale),
      Radius.circular(6 * scale),
    );
    canvas.drawRRect(leftShoe, blackFill);
    canvas.drawRRect(leftShoe, strokePaint);

    // Right Leg
    final rightLegPath = Path()
      ..moveTo(22 * scale, 34 * scale)
      ..lineTo(26 * scale, 62 * scale);
    canvas.drawPath(rightLegPath, strokePaint);

    // Right Shoe
    final rightShoe = RRect.fromRectAndRadius(
      Rect.fromLTWH(12 * scale, 60 * scale, 24 * scale, 12 * scale),
      Radius.circular(6 * scale),
    );
    canvas.drawRRect(rightShoe, blackFill);
    canvas.drawRRect(rightShoe, strokePaint);

    // ── 3. ENVELOPE BODY (RECTANGULAR WITH ROUNDED CORNERS) ──
    final envelopeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(0, 0),
        width: 104 * scale,
        height: 74 * scale,
      ),
      Radius.circular(16 * scale),
    );

    // Body Fill & Stroke
    canvas.drawRRect(envelopeRect, bodyPaint);
    canvas.drawRRect(envelopeRect, strokePaint);

    // Envelope Flap Lines (V-Shape on Top)
    final flapPath = Path()
      ..moveTo(-52 * scale, -37 * scale)
      ..lineTo(0, 8 * scale)
      ..lineTo(52 * scale, -37 * scale);
    canvas.drawPath(flapPath, strokePaint);

    // ── 4. KAWAII FACE (BIG BRIGHT EYES & SMILE) ──
    // Left Eye
    canvas.drawCircle(Offset(-18 * scale, -4 * scale), 5.2 * scale, blackFill);
    canvas.drawCircle(Offset(-16.5 * scale, -5.5 * scale), 1.8 * scale, bodyPaint); // Catchlight

    // Right Eye
    canvas.drawCircle(Offset(18 * scale, -4 * scale), 5.2 * scale, blackFill);
    canvas.drawCircle(Offset(19.5 * scale, -5.5 * scale), 1.8 * scale, bodyPaint); // Catchlight

    // Cute Cheerful Smile (U-shape)
    final mouthPath = Path()
      ..moveTo(-7 * scale, 8 * scale)
      ..quadraticBezierTo(0, 15 * scale, 7 * scale, 8 * scale);
    canvas.drawPath(mouthPath, strokePaint);

    // Rosy Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF85A1).withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-28 * scale, 2 * scale), 4.5 * scale, cheekPaint);
    canvas.drawCircle(Offset(28 * scale, 2 * scale), 4.5 * scale, cheekPaint);

    // ── 5. LEFT ARM HOLDING TRACKER FOLDER / CV ──
    // Left Arm reaching forward
    final leftArmPath = Path()
      ..moveTo(-50 * scale, -4 * scale)
      ..quadraticBezierTo(-66 * scale, 0, -56 * scale, 18 * scale);
    canvas.drawPath(leftArmPath, strokePaint);

    // Tracker Document Folder (Green/Purple Card with Checkmark)
    canvas.save();
    canvas.translate(-64 * scale, 12 * scale);
    canvas.rotate(-0.25);

    // Folder Shape
    final folderRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 34 * scale, height: 42 * scale),
      Radius.circular(6 * scale),
    );
    canvas.drawRRect(folderRect, Paint()..color = const Color(0xFFF3EEFF));
    canvas.drawRRect(folderRect, strokePaint);

    // Document header bar
    final docHeader = RRect.fromRectAndRadius(
      Rect.fromLTWH(-13 * scale, -17 * scale, 26 * scale, 6 * scale),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(docHeader, purpleFill);

    // Document checklist rows
    for (int i = 0; i < 3; i++) {
      final y = -4 * scale + (i * 8 * scale);
      // Small Green Checkmark
      canvas.drawCircle(Offset(-8 * scale, y), 2.2 * scale, greenFill);
      // Line
      canvas.drawLine(
        Offset(-3 * scale, y),
        Offset(11 * scale, y),
        Paint()
          ..color = const Color(0xFF88888D)
          ..strokeWidth = 1.8 * scale
          ..strokeCap = StrokeCap.round,
      );
    }

    // Little hand gripping the folder
    canvas.drawCircle(Offset(10 * scale, 6 * scale), 4.5 * scale, bodyPaint);
    canvas.drawCircle(Offset(10 * scale, 6 * scale), 4.5 * scale, strokePaint);
    canvas.restore();

    // ── 6. RIGHT ARM WAVING WITH THUMBS UP ──
    canvas.save();
    canvas.translate(50 * scale, -4 * scale);
    canvas.rotate(waveArm);

    final rightArmPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(18 * scale, -16 * scale, 24 * scale, -28 * scale);
    canvas.drawPath(rightArmPath, strokePaint);

    // Thumbs Up Hand Glove
    final handCenter = Offset(24 * scale, -28 * scale);
    canvas.drawCircle(handCenter, 6 * scale, bodyPaint);
    canvas.drawCircle(handCenter, 6 * scale, strokePaint);

    // Thumb pointing up
    final thumbPath = Path()
      ..moveTo(handCenter.dx - 2 * scale, handCenter.dy - 4 * scale)
      ..quadraticBezierTo(handCenter.dx, handCenter.dy - 12 * scale, handCenter.dx + 4 * scale, handCenter.dy - 10 * scale)
      ..lineTo(handCenter.dx + 2 * scale, handCenter.dy - 2 * scale);
    canvas.drawPath(thumbPath, bodyPaint);
    canvas.drawPath(thumbPath, strokePaint);

    // Sparkles / Stars near waving hand
    final sparklePaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(handCenter.dx + 12 * scale, handCenter.dy - 12 * scale), 2.5 * scale, sparklePaint);
    canvas.drawCircle(Offset(handCenter.dx + 6 * scale, handCenter.dy - 20 * scale), 1.8 * scale, sparklePaint);

    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrackerOrganizerMascotPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
