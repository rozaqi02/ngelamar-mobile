import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SafeAvatarImage extends StatelessWidget {
  final String? imagePath;
  final double size;
  final Widget? fallback;

  const SafeAvatarImage({
    super.key,
    required this.imagePath,
    this.size = 44.0,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFallback = fallback ??
        Center(
          child: Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: size * 0.54,
          ),
        );

    final path = imagePath?.trim();
    if (path == null || path.isEmpty) {
      return defaultFallback;
    }

    if (kIsWeb ||
        path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:') ||
        path.startsWith('data:')) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => defaultFallback,
      );
    }

    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => defaultFallback,
        );
      }
    } catch (_) {}

    return defaultFallback;
  }
}
