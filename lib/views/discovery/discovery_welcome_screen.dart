import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/prefs_service.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/discovery_explorer_mascot.dart';

/// Authentic Dark-Themed Welcome Experience for Eksplorasi Lowongan.
/// Minimalist, aesthetic, single-statement explanation with large canvas mascot & fluid action button.
class DiscoveryWelcomeScreen extends StatelessWidget {
  const DiscoveryWelcomeScreen({super.key});

  Future<void> _handleClose(BuildContext context) async {
    HapticFeedback.selectionClick();
    await PrefsService.setDiscoveryIntroSeen(true);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF111113),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Top Bar with Fluid Bounce Back Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FluidBounceButton(
                    onTap: () => _handleClose(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E22),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2E2E34)),
                      ),
                      child: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E7090).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0E7090).withValues(alpha: 0.40)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.explore_rounded, size: 14, color: Color(0xFF38BDF8)),
                        SizedBox(width: 6),
                        Text(
                          'Eksplorasi Loker',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 42), // Balanced spacer
                ],
              ),

              const Spacer(),

              // Large Explorer Mascot (Seamless without box/border)
              const Center(
                child: DiscoveryExplorerMascot(
                  width: 265,
                  height: 190,
                ),
              ),

              const Spacer(),

              // Simple Headline with 1 Purple Keyword
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Eksplorasi Karir ',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                    TextSpan(
                      text: 'Impian',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFA78BFA),
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Simple 1-sentence explanation
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Temukan ribuan lowongan kerja resmi terverifikasi dari portal terpercaya secara langsung.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Color(0xFFA1A1AA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Fluid Action Button
              FluidBounceButton(
                onTap: () => _handleClose(context),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C44E4),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5C44E4).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mulai Jelajahi Lowongan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: bottomInset > 0 ? bottomInset + 16 : 24),
            ],
          ),
        ),
      ),
    );
  }
}
