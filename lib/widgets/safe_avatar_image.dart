import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Robust, crash-proof avatar image renderer.
///
/// Features:
/// - Handles null, empty, file paths, web URLs, blobs, and base64 data URIs.
/// - Gracefully falls back to company/user initials and deterministic color palette
///   on decode errors, surviving cold restarts, deleted files, and web refreshes.
/// - Never throws unhandled exceptions that could cause blank screens or crash widget trees.
class SafeAvatarImage extends StatelessWidget {
  final String? imagePath;
  final double size;
  final String? initials;
  final String? displayName;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? fallback;
  final BorderRadius? borderRadius;

  const SafeAvatarImage({
    super.key,
    required this.imagePath,
    this.size = 44.0,
    this.initials,
    this.displayName,
    this.backgroundColor,
    this.textColor,
    this.fallback,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFallback = fallback ?? _buildDefaultFallback();

    final path = imagePath?.trim();
    if (path == null || path.isEmpty) {
      return SizedBox(width: size, height: size, child: effectiveFallback);
    }

    Widget imageWidget;

    if (path.startsWith('data:image/')) {
      try {
        final commaIndex = path.indexOf(',');
        final encoded = commaIndex != -1
            ? path.substring(commaIndex + 1)
            : path;
        imageWidget = Image.memory(
          base64Decode(encoded),
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => effectiveFallback,
        );
      } catch (_) {
        return SizedBox(width: size, height: size, child: effectiveFallback);
      }
    } else if (kIsWeb ||
        path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:')) {
      imageWidget = Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => effectiveFallback,
      );
    } else {
      try {
        final file = File(path);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => effectiveFallback,
          );
        } else {
          return SizedBox(width: size, height: size, child: effectiveFallback);
        }
      } catch (_) {
        return SizedBox(width: size, height: size, child: effectiveFallback);
      }
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return ClipOval(child: imageWidget);
  }

  Widget _buildDefaultFallback() {
    final bg = backgroundColor ?? _resolveColor(displayName ?? initials ?? '');
    final fg = textColor ?? Colors.white;

    final letters = (initials != null && initials!.trim().isNotEmpty)
        ? initials!.trim().toUpperCase()
        : _extractInitials(displayName ?? '');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: letters.isNotEmpty
          ? Text(
              letters,
              style: TextStyle(
                color: fg,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            )
          : Icon(Icons.person_rounded, color: fg, size: size * 0.54),
    );
  }

  String _extractInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (clean.length >= 2) {
      return clean.substring(0, 2).toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  Color _resolveColor(String seed) {
    const palette = [
      Color(0xFF5C44E4), // Brand Indigo
      Color(0xFF0D9488), // Teal
      Color(0xFFE11D48), // Rose
      Color(0xFFD97706), // Amber
      Color(0xFF2563EB), // Blue
      Color(0xFF7C3AED), // Purple
      Color(0xFF059669), // Emerald
      Color(0xFFEA580C), // Orange
    ];
    if (seed.trim().isEmpty) return palette[0];
    final hash = seed.trim().toLowerCase().codeUnits.fold(
      0,
      (acc, c) => acc + c,
    );
    return palette[hash % palette.length];
  }
}
