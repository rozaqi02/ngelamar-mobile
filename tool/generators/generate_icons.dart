// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate All App Icons with Option 1 Mascot Face Zoom', () async {
    Future<List<int>> renderIconPng(int size, {double cornerRadiusRatio = 0.25, bool isPureSquare = false}) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
      final s = size.toDouble();
      final scale = s / 100.0;

      final radius = isPureSquare ? 0.0 : s * cornerRadiusRatio;

      // Background Squircle Gradient
      final bgPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(s, s),
          const [
            Color(0xFF6D54FF),
            Color(0xFF5C44E4),
            Color(0xFF432BC7),
          ],
          const [0.0, 0.5, 1.0],
        );

      if (isPureSquare) {
        canvas.drawRect(Rect.fromLTWH(0, 0, s, s), bgPaint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(radius)),
          bgPaint,
        );
      }

      // Inner radial highlight
      final highlightPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(s * 0.5, s * 0.2),
          s * 0.9,
          [
            Colors.white.withValues(alpha: 0.22),
            Colors.transparent,
          ],
          [0.0, 1.0],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, s, s), highlightPaint);

      // Save & scale for mascot vector paths
      canvas.save();
      canvas.scale(scale);

      // Envelope Body (Zoom 1.35x: 76 x 56 at x:12, y:24, r:14)
      final bodyRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 24, 76, 56),
        const Radius.circular(14),
      );

      // Soft drop shadow
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

      // Left eye (Big sparkle eye)
      final eyePaint = Paint()
        ..color = const Color(0xFF19191B)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(36, 51), 5.5, eyePaint);
      canvas.drawCircle(const Offset(34.2, 49.2), 2.0, Paint()..color = Colors.white);

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
      canvas.drawOval(Rect.fromCenter(center: const Offset(30, 58), width: 9.0, height: 5.0), blushPaint);
      canvas.drawOval(Rect.fromCenter(center: const Offset(70, 58), width: 9.0, height: 5.0), blushPaint);

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

      final picture = recorder.endRecording();
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    }

    // Android targets (with squircle corner radius ~ 0.25)
    final androidTargets = {
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      'android/app/src/main/res/drawable/splash_mascot_icon.png': 192,
      'assets/branding/app_logo_512x512.png': 512,
      'assets/branding/app_logo_1024x1024.png': 1024,
      'assets/images/app_icon.png': 512,
    };

    for (final entry in androidTargets.entries) {
      final bytes = await renderIconPng(entry.value, cornerRadiusRatio: 0.25);
      final file = File(entry.key);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsBytesSync(bytes);
    }

    // iOS targets (Pure square, as iOS applies its own squircle mask)
    final iosTargets = {
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
    };

    for (final entry in iosTargets.entries) {
      final bytes = await renderIconPng(entry.value, isPureSquare: true);
      final file = File(entry.key);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsBytesSync(bytes);
    }

    expect(File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png').existsSync(), isTrue);
    expect(File('assets/branding/app_logo_1024x1024.png').existsSync(), isTrue);
  });
}
