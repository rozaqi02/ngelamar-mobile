import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/prefs_service.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/waving_greeting_mascot.dart';

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Scaffold(
        backgroundColor: const Color(0xFF111113),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FluidBounceButton(
                      onTap: () => _close(context),
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
                const WavingGreetingMascot(width: 250, height: 185),
                const Spacer(),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Jangan Lewatkan ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1,
                          height: 1.08,
                        ),
                      ),
                      TextSpan(
                        text: 'Momennya',
                        style: TextStyle(
                          color: Color(0xFFFF6B5F),
                          fontSize: 29,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          height: 1.08,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 9),
                const Text(
                  'Jadwal seleksi, follow-up, dan kabar penting lamaranmu terkumpul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFD6C5C3),
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                FluidBounceButton(
                  onTap: () => _close(context),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B5F),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Lihat Kabar Lamaranmu',
                      style: TextStyle(
                        color: Color(0xFF24100E),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
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
