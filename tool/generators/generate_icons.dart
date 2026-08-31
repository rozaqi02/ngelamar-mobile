// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paints launcher / splash / branding icons from the same mascot used in-app.
void main() {
  test('Generate launcher icons with flap fold inside the black stroke', () async {
    void paintGradientBackground(
      Canvas canvas,
      double s, {
      double cornerRadius = 0,
    }) {
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
      final rect = Rect.fromLTWH(0, 0, s, s);
      if (cornerRadius <= 0) {
        canvas.drawRect(rect, bgPaint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
          bgPaint,
        );
      }
    }

    void paintHighlight(Canvas canvas, double s) {
      final highlightPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(s * 0.5, s * 0.2),
          s * 0.9,
          [Colors.white.withValues(alpha: 0.22), Colors.transparent],
          [0.0, 1.0],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, s, s), highlightPaint);
    }

    void paintMascot(Canvas canvas, double scale) {
      canvas.save();
      canvas.scale(scale);

      final bodyRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 24, 76, 56),
        const Radius.circular(14),
      );

      final envShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawRRect(bodyRect.shift(const Offset(0, 3)), envShadow);

      canvas.drawRRect(
        bodyRect,
        Paint()
          ..color = const Color(0xFFFAF9F6)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        bodyRect,
        Paint()
          ..color = const Color(0xFF19191B)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke,
      );

      canvas.save();
      canvas.clipRRect(bodyRect.deflate(2.8));
      final foldPaint = Paint()
        ..color = const Color(0xFFE2DBD0)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(24, 32)
          ..lineTo(50, 53)
          ..lineTo(76, 32),
        foldPaint,
      );
      canvas.restore();

      canvas.drawCircle(
        const Offset(36, 51),
        5.5,
        Paint()..color = const Color(0xFF19191B),
      );
      canvas.drawCircle(const Offset(34.2, 49.2), 2.0, Paint()..color = Colors.white);

      final winkPaint = Paint()
        ..color = const Color(0xFF19191B)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(60, 52)
          ..quadraticBezierTo(64, 45, 68, 52),
        winkPaint,
      );

      final blushPaint = Paint()
        ..color = const Color(0xFFFF8A80).withValues(alpha: 0.65);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(30, 58), width: 9.0, height: 5.0),
        blushPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(70, 58), width: 9.0, height: 5.0),
        blushPaint,
      );

      canvas.drawPath(
        Path()
          ..moveTo(48, 57)
          ..quadraticBezierTo(50, 61, 52, 57),
        Paint()
          ..color = const Color(0xFF19191B)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );

      canvas.drawCircle(
        const Offset(86, 40),
        5.0,
        Paint()..color = const Color(0xFFFAF9F6),
      );
      canvas.drawCircle(
        const Offset(86, 40),
        5.0,
        Paint()
          ..color = const Color(0xFF19191B)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );

      canvas.restore();
    }

    Future<List<int>> renderToPng(
      int size,
      void Function(Canvas canvas, double s) paint,
    ) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      );
      paint(canvas, size.toDouble());
      final picture = recorder.endRecording();
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    }

    Future<void> writePng(String path, List<int> bytes) async {
      final file = File(path);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsBytesSync(bytes);
      print('Wrote $path (${bytes.length} bytes)');
    }

    Future<List<int>> renderIconPng(
      int size, {
      double cornerRadiusRatio = 0.25,
      bool isPureSquare = false,
    }) {
      return renderToPng(size, (canvas, s) {
        final radius = isPureSquare ? 0.0 : s * cornerRadiusRatio;
        if (radius > 0) {
          canvas.save();
          canvas.clipRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, s, s),
              Radius.circular(radius),
            ),
          );
        }
        paintGradientBackground(canvas, s, cornerRadius: radius);
        paintHighlight(canvas, s);
        paintMascot(canvas, s / 100.0);
        if (radius > 0) canvas.restore();
      });
    }

    Future<List<int>> renderAdaptiveForeground(int size) {
      return renderToPng(size, (canvas, s) {
        const safe = 72.0 / 108.0;
        final inset = s * (1.0 - safe) / 2.0;
        canvas.translate(inset, inset);
        paintMascot(canvas, (s * safe) / 100.0);
      });
    }

    Future<List<int>> renderRoundIcon(int size) {
      return renderToPng(size, (canvas, s) {
        canvas.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, s, s)));
        paintGradientBackground(canvas, s);
        paintHighlight(canvas, s);
        paintMascot(canvas, s / 100.0);
      });
    }

    const androidLegacy = {
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    };
    const androidRound = {
      'android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png': 192,
    };
    const adaptiveForeground = {
      'android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png': 108,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png': 162,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png': 216,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png': 324,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png': 432,
    };
    const branding = {
      'android/app/src/main/res/drawable/splash_mascot_icon.png': 192,
      'assets/branding/app_logo_512x512.png': 512,
      'assets/branding/app_logo_1024x1024.png': 1024,
      'assets/images/app_icon.png': 512,
    };

    for (final entry in androidLegacy.entries) {
      await writePng(
        entry.key,
        await renderIconPng(entry.value, cornerRadiusRatio: 0.25),
      );
    }
    for (final entry in androidRound.entries) {
      await writePng(entry.key, await renderRoundIcon(entry.value));
    }
    for (final entry in adaptiveForeground.entries) {
      await writePng(entry.key, await renderAdaptiveForeground(entry.value));
    }
    for (final entry in branding.entries) {
      await writePng(
        entry.key,
        await renderIconPng(entry.value, cornerRadiusRatio: 0.25),
      );
    }

    expect(
      File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png')
          .existsSync(),
      isTrue,
    );
  });
}
