import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/waving_greeting_mascot.dart';

/// Google Material You (Material 3) Welcome Screen for Daftar Lamaran (Job Tracker).
class JobListWelcomeScreen extends StatelessWidget {
  const JobListWelcomeScreen({super.key});

  Future<void> _handleClose(BuildContext context) async {
    HapticFeedback.selectionClick();
    await PrefsService.setJobListIntroSeen(true);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = AppTheme.isDark(context);

    final bgColor = isDark ? const Color(0xFF161224) : const Color(0xFFF6F2FC);
    final tonalBtnColor =
        isDark ? const Color(0xFF261E3D) : const Color(0xFFEADBFC);
    final tonalIconColor =
        isDark ? const Color(0xFFD8B4FE) : const Color(0xFF4A1A78);

    final txtPri = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final txtSec = isDark ? const Color(0xFFC7BED9) : const Color(0xFF4B5563);

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
                const SizedBox(height: 12),

                // Top Bar with Material 3 Tonal Icon Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FluidBounceButton(
                      onTap: () => _handleClose(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: tonalBtnColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_down,
                          color: tonalIconColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Mascot Canvas
                const Center(
                  child: WavingGreetingMascot(width: 270, height: 205),
                ),

                const Spacer(),

                // Material You Headline
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Kelola Lamaran ',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: txtPri,
                          letterSpacing: -1.0,
                          height: 1.12,
                        ),
                      ),
                      const TextSpan(
                        text: 'Terstruktur',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6750A4),
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
                    'Pantau seluruh tahapan seleksi, jadwal interview, dan progres karirmu secara rapi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: txtSec,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // Material 3 Filled Button
                FluidBounceButton(
                  onTap: () => _handleClose(context),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6750A4),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Mulai Kelola Lamaran',
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

                SizedBox(height: bottomInset > 0 ? bottomInset + 16 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
