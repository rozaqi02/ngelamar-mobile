import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/job_provider.dart';
import '../services/prefs_service.dart';
import 'main_navigation.dart';

/// Splash Screen — YouTube-style icon entrance animation,
/// then checks onboarding state and routes accordingly.
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
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Logo scale: 0.3 → 1.0
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );

    // Logo fade-in: 0 → 1
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // Title text fade: 0 → 1
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );

    // Title text slide: from bottom 20px → 0
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation, then navigate after delay
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 600), _navigate);
    });
  }

  Future<void> _navigate() async {
    final isDone = await PrefsService.isOnboardingDone();
    if (!mounted) return;

    if (isDone) {
      _goToMain();
    } else {
      _goToOnboarding();
    }
  }

  void _goToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  void _goToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final txtPri = Theme.of(context).colorScheme.onSurface;
    final txtSec = AppTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon with bounce-in
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => FadeTransition(
                opacity: _fadeAnim,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A84FF).withValues(alpha: 0.5),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.briefcase_fill,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App name slide-up
            FadeTransition(
              opacity: _titleFade,
              child: SlideTransition(
                position: _titleSlide,
                child: Column(
                  children: [
                    Text(
                      'Ngelamar',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: txtPri,
                        letterSpacing: -1.0,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Personal Career CRM',
                      style: TextStyle(
                        fontSize: 14,
                        color: txtSec,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Onboarding Screen — Name Input (First Launch Only)
// ─────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(
      () => setState(() => _isValid = _nameController.text.trim().length >= 2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isValid) return;
    final name = _nameController.text.trim();
    await ref.read(jobProvider.notifier).setUserName(name);
    await PrefsService.setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final txtPri = Theme.of(context).colorScheme.onSurface;
    final txtSec = AppTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(CupertinoIcons.briefcase_fill,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 32),

              Text(
                'Halo, siapa kamu?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: txtPri,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan namamu agar Ngelamar bisa menyapamu setiap hari.',
                style: TextStyle(
                  fontSize: 15,
                  color: txtSec,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w500),
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Nama kamu...',
                  prefixIcon: Icon(CupertinoIcons.person, size: 18),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isValid ? 1.0 : 0.4,
                  child: ElevatedButton(
                    onPressed: _isValid ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.systemBlue,
                      disabledBackgroundColor: AppTheme.systemBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Mulai Ngelamar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
