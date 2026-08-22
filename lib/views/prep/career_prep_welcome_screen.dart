import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/prefs_service.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/career_prep_mascot.dart';

/// Authentic Dark-Themed Welcome Experience for Persiapan Karir.
/// Minimalist, aesthetic, single-statement explanation with large canvas mascot & fluid action button.
class CareerPrepWelcomeScreen extends StatelessWidget {
  const CareerPrepWelcomeScreen({super.key});

  Future<void> _handleClose(BuildContext context) async {
    HapticFeedback.selectionClick();
    await PrefsService.setCareerPrepIntroSeen(true);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Scaffold(
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FluidBounceButton(
                      onTap: () => _handleClose(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E22),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF303036)),
                        ),
                        child: const Icon(
                          CupertinoIcons.chevron_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Large Prep Mascot (Seamless without box/border)
                const Center(child: CareerPrepMascot(width: 265, height: 190)),

                const Spacer(),

                // Simple Headline with 1 Purple Keyword
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Kuasai Tahapan ',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -1.1,
                          height: 1.08,
                        ),
                      ),
                      TextSpan(
                        text: 'Seleksi',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF8BA38),
                          letterSpacing: -1.1,
                          height: 1.08,
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
                    'Siapkan checklist berkas ATS, latihan interview metode STAR, dan simulasi gaji UMR.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: Color(0xFFE0D2AF),
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
                      color: const Color(0xFFF8BA38),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFF8BA38,
                          ).withValues(alpha: 0.38),
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
                            'Mulai Latihan Sekarang',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19130A),
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF19130A),
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
