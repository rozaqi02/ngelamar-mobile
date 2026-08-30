import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_version.dart';
import '../services/prefs_service.dart';
import '../services/remote_config_service.dart';
import 'landing/landing_screen.dart';
import 'main_navigation.dart';

import '../widgets/app_mascot_icon.dart';

/// Splash Screen — Warm Neo-Modern Entrance with Elastic Animations.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      if (mounted) _navigate();
    });
  }

  Future<void> _navigate() async {
    // Non-blocking refresh runs in background; check cached version rules immediately
    if (RemoteConfigService.requiresUpdate(AppVersion.version)) {
      if (!mounted) return;
      await _showRequiredUpdate();
      return;
    }
    final isDone = await PrefsService.isOnboardingDone();
    if (!mounted) return;

    if (isDone) {
      _goToMain();
    } else {
      _goToLanding();
    }
  }

  Future<void> _showRequiredUpdate() async {
    final storeUrl = RemoteConfigService.minimumSupportedStoreUrl;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          icon: const Icon(Icons.system_update_alt_rounded),
          title: const Text('Pembaruan diperlukan'),
          content: const Text(
            'Versi Ngelamar ini sudah tidak didukung. Perbarui aplikasi agar data dan fitur tetap aman.',
          ),
          actions: [
            FilledButton(
              onPressed: storeUrl == null
                  ? null
                  : () => launchUrl(
                      Uri.parse(storeUrl),
                      mode: LaunchMode.externalApplication,
                    ),
              child: const Text('Perbarui aplikasi'),
            ),
          ],
        ),
      ),
    );
  }

  void _goToLanding() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LandingScreen()));
  }

  void _goToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF111113);
    const txtPri = Colors.white;
    const txtSec = Color(0xFFA1A1AA);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon Logo with Mascot, Elastic Scale & Subtle Shadow
            ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: const AppMascotIcon(size: 108, borderRadius: 32),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fadeAnim,
              child: const Column(
                children: [
                  Text(
                    'Ngelamar',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: txtPri,
                      letterSpacing: -1.0,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Teman Setia Cari Kerja',
                    style: TextStyle(
                      fontSize: 14,
                      color: txtSec,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
