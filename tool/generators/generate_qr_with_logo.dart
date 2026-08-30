// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate High-Res QR Code with Authentic App Icon Logo in Center', () async {
    final qrFile = File('assets/branding/idka_produk_qr.png');
    final iconFile = File('assets/branding/app_logo_1024x1024.png');

    expect(qrFile.existsSync(), isTrue);
    expect(iconFile.existsSync(), isTrue);

    final qrBytes = await qrFile.readAsBytes();
    final iconBytes = await iconFile.readAsBytes();

    final qrCompleter = Completer<ui.Image>();
    ui.decodeImageFromList(qrBytes, qrCompleter.complete);
    final qrImg = await qrCompleter.future;

    final iconCompleter = Completer<ui.Image>();
    ui.decodeImageFromList(iconBytes, iconCompleter.complete);
    final iconImg = await iconCompleter.future;

    const size = 1024.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    // 1. Draw base QR Code
    canvas.drawImageRect(
      qrImg,
      Rect.fromLTWH(0, 0, qrImg.width.toDouble(), qrImg.height.toDouble()),
      const Rect.fromLTWH(0, 0, size, size),
      Paint()..filterQuality = FilterQuality.high,
    );

    // 2. Center badge size (~230x230 px, exactly 22.5% of total size - within 30% Level H ECC limit)
    const badgeSize = 232.0;
    const badgeLeft = (size - badgeSize) / 2.0;
    const badgeTop = (size - badgeSize) / 2.0;
    final badgeRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(badgeLeft, badgeTop, badgeSize, badgeSize),
      const Radius.circular(52),
    );

    // Draw clean white protective background pad with soft drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(badgeRect.shift(const Offset(0, 4)), shadowPaint);

    final whitePadPaint = Paint()..color = Colors.white;
    canvas.drawRRect(badgeRect, whitePadPaint);

    // Draw fine outer stroke on white pad
    final padBorderPaint = Paint()
      ..color = const Color(0xFFE5E0D5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(badgeRect, padBorderPaint);

    // 3. Draw authentic app icon inside the white badge (size: 204x204, 14px padding)
    const iconInnerSize = 204.0;
    const iconLeft = (size - iconInnerSize) / 2.0;
    const iconTop = (size - iconInnerSize) / 2.0;
    final iconRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(iconLeft, iconTop, iconInnerSize, iconInnerSize),
      const Radius.circular(44),
    );

    canvas.save();
    canvas.clipRRect(iconRRect);
    canvas.drawImageRect(
      iconImg,
      Rect.fromLTWH(0, 0, iconImg.width.toDouble(), iconImg.height.toDouble()),
      const Rect.fromLTWH(iconLeft, iconTop, iconInnerSize, iconInnerSize),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    // 4. Subtle inner border for crisp definition
    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(iconRRect, innerBorderPaint);

    final picture = recorder.endRecording();
    final finalImg = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await finalImg.toByteData(format: ui.ImageByteFormat.png);
    final finalPngBytes = byteData!.buffer.asUint8List();

    // Save to destinations
    await File('assets/branding/idka_produk_qr_with_logo.png').writeAsBytes(finalPngBytes);
    await File('idka_produk_qr_with_logo.png').writeAsBytes(finalPngBytes);
    
    // Also copy to artifact dir for preview
    const artifactDir = 'C:/Users/rojak/.gemini/antigravity/brain/718f05df-28b5-4f57-bada-70527ab6714a';
    if (Directory(artifactDir).existsSync()) {
      await File('$artifactDir/idka_produk_qr_with_logo.png').writeAsBytes(finalPngBytes);
    }

    debugPrint('SUCCESS: QR Code with Authentic App Icon generated (1024x1024 PNG).');
  });
}
