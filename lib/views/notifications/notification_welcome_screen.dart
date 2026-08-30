import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/waving_greeting_mascot.dart';

/// Google Material You (Material 3) Welcome Screen for Kabar & Notifikasi.
class NotificationWelcomeScreen extends StatelessWidget {
  const NotificationWelcomeScreen({super.key});

  Future<void> _close(BuildContext context) async {
    HapticFeedback.selectionClick();
    await PrefsService.setNotificationIntroSeen(true);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isDark = AppTheme.isDark(context);

    final bgColor = isDark ? const Color(0xFF1F1115) : const Color(0xFFFCF2F2);
    final txtPri = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final txtSec = isDark ? const Color(0xFFDCC8CA) : const Color(0xFF4B5563);

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
                  child: WavingGreetingMascot(width: 220, height: 165),
                ),

                const Spacer(),

                // Material You Headline
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Jangan Lewatkan ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: txtPri,
                          letterSpacing: -1.0,
                          height: 1.12,
                        ),
                      ),
                      const TextSpan(
                        text: 'Momennya',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFBA1A1A),
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
                    'Jadwal seleksi, follow-up, dan kabar penting lamaranmu terkumpul di sini.',
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
                  onTap: () => _close(context),
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lihat Kabar Lamaranmu',
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
