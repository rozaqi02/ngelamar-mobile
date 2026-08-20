import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Renders authentic company icons (GoTo, Shopee, BCA, Google, Uber, Amazon, Microsoft, etc.)
/// or a crisp stylized monogram inside a white circular badge.
class CompanyLogoBadge extends StatelessWidget {
  final String companyName;
  final double size;
  final Color? backgroundColor;

  const CompanyLogoBadge({
    super.key,
    required this.companyName,
    this.size = 40.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final lower = companyName.toLowerCase().trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: _buildBrandIcon(lower),
      ),
    );
  }

  Widget _buildBrandIcon(String lower) {
    if (lower.contains('goto') || lower.contains('gojek')) {
      return _buildGoToLogo();
    } else if (lower.contains('shopee')) {
      return _buildShopeeLogo();
    } else if (lower.contains('bca')) {
      return _buildBcaLogo();
    } else if (lower.contains('uber')) {
      return _buildUberLogo();
    } else if (lower.contains('amazon')) {
      return _buildAmazonLogo();
    } else if (lower.contains('microsoft')) {
      return _buildMicrosoftLogo();
    } else if (lower.contains('google')) {
      return _buildGoogleLogo();
    } else if (lower.contains('apple')) {
      return Icon(Icons.apple, size: size * 0.58, color: Colors.black);
    } else if (lower.contains('meta') || lower.contains('facebook')) {
      return Icon(Icons.facebook, size: size * 0.58, color: const Color(0xFF1877F2));
    } else if (lower.contains('telkom')) {
      return Icon(Icons.hub, size: size * 0.52, color: const Color(0xFFED1B24));
    }

    // Default stylized monogram
    return Text(
      _getMonogram(companyName),
      style: TextStyle(
        fontSize: size * 0.40,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF121214),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildGoToLogo() {
    return Container(
      width: size * 0.62,
      height: size * 0.62,
      decoration: const BoxDecoration(
        color: Color(0xFF00AA13), // GoTo / Gojek Green
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size * 0.22,
          height: size * 0.22,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildShopeeLogo() {
    return Icon(
      Icons.shopping_bag_outlined,
      size: size * 0.56,
      color: const Color(0xFFEE4D2D), // Shopee Orange
    );
  }

  Widget _buildBcaLogo() {
    return Text(
      'BCA',
      style: TextStyle(
        fontSize: size * 0.32,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF003D79), // BCA Navy
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildUberLogo() {
    return Container(
      width: size * 0.65,
      height: size * 0.65,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size * 0.26,
          height: size * 0.26,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildAmazonLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'a',
          style: TextStyle(
            fontSize: size * 0.58,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            fontFamily: 'serif',
            height: 1.0,
          ),
        ),
        Positioned(
          bottom: size * 0.18,
          child: Container(
            width: size * 0.36,
            height: 2.8,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9900),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMicrosoftLogo() {
    final s = size * 0.22;
    const gap = 1.8;
    return SizedBox(
      width: s * 2 + gap,
      height: s * 2 + gap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: s, height: s, color: const Color(0xFFF25022)),
              const SizedBox(width: gap),
              Container(width: s, height: s, color: const Color(0xFF7FBA00)),
            ],
          ),
          const SizedBox(height: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: s, height: s, color: const Color(0xFF00A4EF)),
              const SizedBox(width: gap),
              Container(width: s, height: s, color: const Color(0xFFFFB900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return Text(
      'G',
      style: TextStyle(
        fontSize: size * 0.56,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF4285F4),
        fontFamily: 'sans-serif',
      ),
    );
  }

  String _getMonogram(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'N';
    final words = clean.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }
}
