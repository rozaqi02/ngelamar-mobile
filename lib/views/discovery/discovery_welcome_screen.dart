import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/discovery_explorer_mascot.dart';

/// Google Material You (Material 3) Welcome Screen for Cari Lokerku.
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
    final isDark = AppTheme.isDark(context);

    final bgColor = isDark ? const Color(0xFF111A13) : const Color(0xFFF1F8F1);
    final txtPri = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final txtSec = isDark ? const Color(0xFFA7B8AA) : const Color(0xFF4B5563);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),

                const Spacer(),

                // Mascot Canvas
                const Center(
                  child: DiscoveryExplorerMascot(width: 220, height: 160),
                ),

                const Spacer(),

                // Material You Headline
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Eksplorasi Karir ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: txtPri,
                          letterSpacing: -1.0,
                          height: 1.12,
                        ),
                      ),
                      const TextSpan(
                        text: 'Impian',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                          letterSpacing: -1.0,
                          height: 1.12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Temukan ribuan lowongan kerja resmi terverifikasi dari portal terpercaya secara langsung.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: txtSec,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Material 3 Filled Button
                FluidBounceButton(
                  onTap: () => _handleClose(context),
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Mulai Jelajahi Lowongan',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: bottomInset > 0 ? bottomInset + 8 : 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
