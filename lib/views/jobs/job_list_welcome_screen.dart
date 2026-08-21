import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/prefs_service.dart';
import '../../widgets/animated_envelope_stack_graphic.dart';
import '../../widgets/apple_animations.dart';

/// Authentic Dark-Themed Welcome Screen for Daftar Lamaran (Job Tracker).
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // ── TOP NAV BAR ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FluidBounceButton(
                    onTap: () => _handleClose(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_rounded, size: 14, color: Color(0xFF4ADE80)),
                        SizedBox(width: 6),
                        Text(
                          'Daftar Lamaran',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),

              const Spacer(flex: 2),

              // ── ANIMATED ENVELOPE STACK ILLUSTRATION ──
              Center(
                child: AnimatedEnvelopeStackGraphic(
                  width: (size.width * 0.82).clamp(280.0, 360.0),
                  height: 250,
                  accentColor: const Color(0xFF22C55E),
                  topBadgeText: 'Interview HR • H-1',
                  heroBadgeText: 'Status Terpantau',
                ),
              ),

              const Spacer(flex: 3),

              // ── HEADLINE & ACCENT HIGHLIGHT (STYLE REFERENSI) ──
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Kelola Lamaran\nLebih ',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.18,
                      ),
                    ),
                    TextSpan(
                      text: 'Terstruktur',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF22C55E),
                        letterSpacing: -0.8,
                        height: 1.18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── SUBTITLE IN INDONESIAN ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Pantau seluruh tahapan seleksi, jadwal interview, bukti screenshot, dan riwayat follow-up secara rapi dalam satu tempat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Color(0xFFA1A1AA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // ── FULL-WIDTH ACTION BUTTON ──
              FluidBounceButton(
                onTap: () => _handleClose(context),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.40),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Mulai Kelola Lamaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: bottomInset > 0 ? bottomInset + 16 : 28),
            ],
          ),
        ),
      ),
    );
  }
}

