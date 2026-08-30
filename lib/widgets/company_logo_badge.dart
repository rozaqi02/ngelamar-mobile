import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Renders code-native vector marks for fictional sample companies, authentic
/// company icons, custom uploaded logos, or a crisp monogram fallback.
class CompanyLogoBadge extends StatelessWidget {
  final String companyName;
  final double size;
  final Color? backgroundColor;
  final String? customImagePath;

  const CompanyLogoBadge({
    super.key,
    required this.companyName,
    this.size = 40.0,
    this.backgroundColor,
    this.customImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final lower = companyName.toLowerCase().trim();
    final sampleBrand = _sampleBrand(lower);

    final customPath = customImagePath?.trim();
    final isWebOrUrl =
        kIsWeb ||
        (customPath != null &&
            (customPath.startsWith('http://') ||
                customPath.startsWith('https://') ||
                customPath.startsWith('blob:') ||
                customPath.startsWith('data:')));

    bool hasValidLocalFile = false;
    if (!kIsWeb && customPath != null && customPath.isNotEmpty && !isWebOrUrl) {
      try {
        hasValidLocalFile = File(customPath).existsSync();
      } catch (_) {}
    }

    final hasCustomImage =
        (isWebOrUrl && customPath != null && customPath.isNotEmpty) ||
        hasValidLocalFile;

    final Widget logo = hasCustomImage
        ? (isWebOrUrl
              ? Image.network(
                  customPath!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      Center(child: _buildBrandIcon(lower)),
                )
              : Image.file(
                  File(customPath!),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  cacheWidth: (size * MediaQuery.of(context).devicePixelRatio)
                      .round(),
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      Center(child: _buildBrandIcon(lower)),
                ))
        : sampleBrand != null
        ? Center(
            child: CustomPaint(
              size: Size.square(size * 0.74),
              painter: _SampleCompanyLogoPainter(sampleBrand),
            ),
          )
        : Center(child: _buildBrandIcon(lower));

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
      child: ClipOval(child: logo),
    );
  }

  _SampleCompanyBrand? _sampleBrand(String lower) {
    if (lower.contains('nusa') || lower.contains('nawa')) {
      return _SampleCompanyBrand.nusa;
    }
    if (lower.contains('karsa')) {
      return _SampleCompanyBrand.karsa;
    }
    if (lower.contains('bumi')) {
      return _SampleCompanyBrand.bumi;
    }
    if (lower.contains('aruna')) {
      return _SampleCompanyBrand.aruna;
    }
    if (lower.contains('sora')) {
      return _SampleCompanyBrand.sora;
    }
    if (lower.contains('tera')) {
      return _SampleCompanyBrand.tera;
    }
    return null;
  }

  Widget _buildBrandIcon(String lower) {
    final sampleBrand = _sampleBrand(lower);
    if (sampleBrand != null) {
      return CustomPaint(
        size: Size.square(size * 0.74),
        painter: _SampleCompanyLogoPainter(sampleBrand),
      );
    }
    if (lower.contains('idka')) {
      return Image.asset(
        'assets/portal_logos/idka_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildGoToLogo(),
      );
    } else if (lower.contains('goto') || lower.contains('gojek')) {
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
      return Icon(
        Icons.facebook,
        size: size * 0.58,
        color: const Color(0xFF1877F2),
      );
    } else if (lower.contains('telkom')) {
      return Icon(Icons.hub, size: size * 0.52, color: const Color(0xFFED1B24));
    } else if (lower.contains('glints')) {
      return _buildGlintsLogo();
    } else if (lower.contains('jobstreet')) {
      return _buildJobStreetLogo();
    } else if (lower.contains('linkedin')) {
      return _buildLinkedInLogo();
    } else if (lower.contains('indeed')) {
      return _buildIndeedLogo();
    } else if (lower.contains('kalibrr')) {
      return _buildKalibrrLogo();
    } else if (lower.contains('kitalulus')) {
      return _buildKitaLulusLogo();
    } else if (lower.contains('nusa') || lower.contains('nawa')) {
      return _buildNusaTechLogo();
    } else if (lower.contains('karsa')) {
      return _buildKarsaLabsLogo();
    } else if (lower.contains('bumi')) {
      return _buildBumiDataLogo();
    } else if (lower.contains('aruna')) {
      return _buildArunaMartLogo();
    } else if (lower.contains('sora')) {
      return _buildSoraBankLogo();
    } else if (lower.contains('tera')) {
      return _buildTeraMediaLogo();
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

  Widget _buildGlintsLogo() {
    return Container(
      width: size * 0.72,
      height: size * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF0E7090),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: size * 0.44,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildJobStreetLogo() {
    return Container(
      width: size * 0.72,
      height: size * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF1C3F94),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'JS',
          style: TextStyle(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedInLogo() {
    return Container(
      width: size * 0.72,
      height: size * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF0A66C2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'in',
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildIndeedLogo() {
    return Container(
      width: size * 0.72,
      height: size * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF2164F3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'i',
          style: TextStyle(
            fontSize: size * 0.44,
            fontWeight: FontWeight.w900,
            fontFamily: 'serif',
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildKalibrrLogo() {
    return Container(
      width: size * 0.72,
      height: size * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF00A859),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'K',
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildKitaLulusLogo() {
    return Container(
      width: size * 0.72,
      height: size * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF5C44E4),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'KL',
          style: TextStyle(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildNusaTechLogo() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB), // Electric Royal Blue
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.code_rounded, size: size * 0.54, color: Colors.white),
      ),
    );
  }

  Widget _buildKarsaLabsLogo() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF8B5CF6), // Vibrant Violet
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          size: size * 0.52,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBumiDataLogo() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF10B981), // Emerald Mint
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.insights_rounded,
          size: size * 0.52,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildArunaMartLogo() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFF97316), // Sunset Orange
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.shopping_bag_rounded,
          size: size * 0.52,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSoraBankLogo() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF0284C7), // Sky Blue
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.account_balance_rounded,
          size: size * 0.50,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTeraMediaLogo() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFEC4899), // Vivid Pink
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.campaign_rounded,
          size: size * 0.54,
          color: Colors.white,
        ),
      ),
    );
  }
}

enum _SampleCompanyBrand { nusa, karsa, bumi, aruna, sora, tera }

/// Six small, code-native marks for the fictional sample companies. These are
/// drawn from paths and primitives so they remain sharp at every display size.
class _SampleCompanyLogoPainter extends CustomPainter {
  final _SampleCompanyBrand brand;

  const _SampleCompanyLogoPainter(this.brand);

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..isAntiAlias = true;

    switch (brand) {
      case _SampleCompanyBrand.nusa:
        final stroke = Paint()
          ..color = const Color(0xFF2563EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * 0.18
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final path = Path()
          ..moveTo(unit * .20, unit * .78)
          ..lineTo(unit * .20, unit * .22)
          ..lineTo(unit * .80, unit * .78)
          ..lineTo(unit * .80, unit * .22);
        canvas.drawPath(path, stroke);
        paint.color = const Color(0xFF0F3B8F);
        canvas.drawCircle(center, unit * .09, paint);
        break;
      case _SampleCompanyBrand.karsa:
        final colors = [
          const Color(0xFFD946EF),
          const Color(0xFF7C3AED),
          const Color(0xFFF472B6),
          const Color(0xFF5B21B6),
        ];
        for (var index = 0; index < 4; index++) {
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(index * math.pi / 2);
          final petal = Path()
            ..moveTo(0, -unit * .43)
            ..quadraticBezierTo(unit * .27, -unit * .17, 0, 0)
            ..quadraticBezierTo(-unit * .27, -unit * .17, 0, -unit * .43)
            ..close();
          paint.color = colors[index];
          canvas.drawPath(petal, paint);
          canvas.restore();
        }
        paint.color = Colors.white;
        canvas.drawCircle(center, unit * .105, paint);
        break;
      case _SampleCompanyBrand.bumi:
        paint.color = const Color(0xFF059669);
        canvas.drawCircle(center, unit * .42, paint);
        final line = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * .09
          ..strokeCap = StrokeCap.round;
        final path = Path()
          ..moveTo(unit * .19, unit * .64)
          ..quadraticBezierTo(unit * .38, unit * .47, unit * .51, unit * .57)
          ..lineTo(unit * .79, unit * .30);
        canvas.drawPath(path, line);
        for (final point in [
          Offset(unit * .24, unit * .61),
          Offset(unit * .51, unit * .57),
          Offset(unit * .77, unit * .31),
        ]) {
          canvas.drawCircle(point, unit * .075, Paint()..color = Colors.white);
        }
        break;
      case _SampleCompanyBrand.aruna:
        paint.color = const Color(0xFFF97316);
        final bag = RRect.fromRectAndRadius(
          Rect.fromLTWH(unit * .15, unit * .35, unit * .70, unit * .48),
          Radius.circular(unit * .13),
        );
        canvas.drawRRect(bag, paint);
        final handle = Paint()
          ..color = const Color(0xFFF97316)
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * .11
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromLTWH(unit * .31, unit * .16, unit * .38, unit * .38),
          math.pi,
          math.pi,
          false,
          handle,
        );
        paint.color = const Color(0xFFFFE082);
        canvas.drawCircle(Offset(unit * .50, unit * .60), unit * .13, paint);
        break;
      case _SampleCompanyBrand.sora:
        paint.color = const Color(0xFF2563EB);
        final roof = Path()
          ..moveTo(unit * .13, unit * .40)
          ..lineTo(unit * .50, unit * .17)
          ..lineTo(unit * .87, unit * .40)
          ..close();
        canvas.drawPath(roof, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(unit * .16, unit * .72, unit * .68, unit * .12),
            Radius.circular(unit * .05),
          ),
          paint,
        );
        paint.color = const Color(0xFF60A5FA);
        for (final x in [.28, .50, .72]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                unit * x - unit * .055,
                unit * .43,
                unit * .11,
                unit * .28,
              ),
              Radius.circular(unit * .035),
            ),
            paint,
          );
        }
        break;
      case _SampleCompanyBrand.tera:
        paint.color = const Color(0xFFE11D48);
        final play = Path()
          ..moveTo(unit * .22, unit * .17)
          ..lineTo(unit * .22, unit * .83)
          ..lineTo(unit * .76, unit * .50)
          ..close();
        canvas.drawPath(play, paint);
        final signal = Paint()
          ..color = const Color(0xFFFB7185)
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * .075
          ..strokeCap = StrokeCap.round;
        for (final scale in [.25, .40]) {
          canvas.drawArc(
            Rect.fromCircle(
              center: Offset(unit * .61, unit * .35),
              radius: unit * scale,
            ),
            -math.pi / 2,
            math.pi / 2,
            false,
            signal,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SampleCompanyLogoPainter oldDelegate) =>
      oldDelegate.brand != brand;
}
