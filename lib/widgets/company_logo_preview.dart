import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_motion.dart';
import 'company_logo_badge.dart';

/// Full-screen company mark preview that continues the job-detail hero.
class CompanyLogoPreviewPage extends StatelessWidget {
  final String companyName;
  final String? customImagePath;
  final String heroTag;

  const CompanyLogoPreviewPage({
    super.key,
    required this.companyName,
    required this.heroTag,
    this.customImagePath,
  });

  static Future<void> open(
    BuildContext context, {
    required String companyName,
    required String heroTag,
    String? customImagePath,
  }) {
    HapticFeedback.selectionClick();
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.78),
        transitionDuration: const Duration(milliseconds: 340),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) {
          return CompanyLogoPreviewPage(
            companyName: companyName,
            customImagePath: customImagePath,
            heroTag: heroTag,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Tutup pratinjau',
                  ),
                ),
              ),
              const Spacer(),
              Hero(
                tag: heroTag,
                createRectTween: companyLogoRectTween,
                flightShuttleBuilder: companyLogoFlightShuttle,
                placeholderBuilder: companyLogoHeroPlaceholder,
                child: CompanyLogoBadge(
                  companyName: companyName,
                  customImagePath: customImagePath,
                  size: 220,
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  companyName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ketuk di mana saja untuk menutup',
                style: TextStyle(
                  color: Color(0xFFD4D4D8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
