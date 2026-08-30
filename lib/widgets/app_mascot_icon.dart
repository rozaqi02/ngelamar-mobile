import 'package:flutter/material.dart';

/// App Mascot Icon (Option 1: Balanced Close-Up 1.35x).
/// Features:
/// - Friendly sparkling left eye + joyful wink right eye
/// - Rosy blush cheeks
/// - Cute smiling mouth
/// - Envelope fold flap line (cream accent)
/// - Peek waving glove on side
/// - Rich indigo/violet gradient squircle with soft inner glow
class AppMascotIcon extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool showBackground;
  final bool animate;

  const AppMascotIcon({
    super.key,
    this.size = 96,
    this.borderRadius,
    this.showBackground = true,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (size * 0.25);

    Widget content = CustomPaint(
      size: Size(size, size),
      painter: _AppMascotIconPainter(),
    );

    if (!showBackground) return content;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D54FF), Color(0xFF5C44E4), Color(0xFF432BC7)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C44E4).withValues(alpha: 0.38),
            blurRadius: size * 0.32,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class _AppMascotIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale);

    // Inner radial highlight on squircle
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.6),
        radius: 0.9,
        colors: [Colors.white.withValues(alpha: 0.22), Colors.transparent],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), highlightPaint);

    // ── ENVELOPE BODY (ZOOM 1.35x: 76 x 56 at x:12, y:24, r:14) ──
    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 24, 76, 56),
      const Radius.circular(14),
    );

    // Soft drop shadow for envelope
    final envShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(bodyRect.shift(const Offset(0, 3)), envShadow);

    // Envelope white fill
    final bodyPaint = Paint()
      ..color = const Color(0xFFFAF9F6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRect, bodyPaint);

    // Envelope dark border
    final borderPaint = Paint()
      ..color = const Color(0xFF19191B)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bodyRect, borderPaint);

    // Flap fold line
    final foldPaint = Paint()
      ..color = const Color(0xFFE2DBD0)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final foldPath = Path()
      ..moveTo(14, 28)
      ..lineTo(50, 56)
      ..lineTo(86, 28);
    canvas.drawPath(foldPath, foldPaint);

    // ── MASKOT EYES & SMILE ──
    // Left eye (Big sparkle eye)
    final eyePaint = Paint()
      ..color = const Color(0xFF19191B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(36, 51), 5.5, eyePaint);
    canvas.drawCircle(
      const Offset(34.2, 49.2),
      2.0,
      Paint()..color = Colors.white,
    );

    // Right eye (Joyful wink)
    final winkPaint = Paint()
      ..color = const Color(0xFF19191B)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final winkPath = Path()
      ..moveTo(60, 52)
      ..quadraticBezierTo(64, 45, 68, 52);
    canvas.drawPath(winkPath, winkPaint);

    // Rosy Pink Cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(30, 58), width: 9.0, height: 5.0),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(70, 58), width: 9.0, height: 5.0),
      blushPaint,
    );

    // Cute Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF19191B)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final smilePath = Path()
      ..moveTo(48, 57)
      ..quadraticBezierTo(50, 61, 52, 57);
    canvas.drawPath(smilePath, smilePaint);

    // Peek waving glove hand on side
    final handPaint = Paint()
      ..color = const Color(0xFFFAF9F6)
      ..style = PaintingStyle.fill;
    final handBorder = Paint()
      ..color = const Color(0xFF19191B)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(86, 40), 5.0, handPaint);
    canvas.drawCircle(const Offset(86, 40), 5.0, handBorder);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
