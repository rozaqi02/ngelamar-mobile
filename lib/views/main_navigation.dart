import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/job_provider.dart';
import '../services/prefs_service.dart';
import '../widgets/apple_toast.dart';
import '../widgets/app_layout_metrics.dart';
import '../widgets/app_tour_overlay.dart';
import '../widgets/welcome_screen_route.dart';
import 'dashboard/dashboard_screen.dart';
import 'discovery/discovery_welcome_screen.dart';
import 'discovery/job_discovery_screen.dart';
import 'jobs/job_list_screen.dart';
import 'jobs/job_list_welcome_screen.dart';
import 'prep/career_prep_welcome_screen.dart';
import 'prep/fresh_grad_prep_screen.dart';
import 'settings/settings_screen.dart';

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}

/// Floating Capsule Pill Navigation Bar (5 Items).
/// 1. Beranda (Priority Overlapping Deck)
/// 2. Persiapan Karir (Checklist, Modul & Tips Karir)
/// 3. Daftar Lamaran (Full Tracker & Status Management)
/// 4. Portal Loker (Akses Cepat Portal Karir Resmi)
/// 5. Profil (Pengaturan, Resume & Akun)
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;
  bool _isAppTourVisible = false;

  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  static const _items = [
    _NavItem(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Beranda',
    ),
    _NavItem(
      activeIcon: Icons.school_rounded,
      inactiveIcon: Icons.school_outlined,
      label: 'Siapkan Karir',
    ),
    _NavItem(
      activeIcon: Icons.mail_rounded,
      inactiveIcon: Icons.mail_outline_rounded,
      label: 'Daftar Lamaran',
    ),
    _NavItem(
      activeIcon: Icons.travel_explore_rounded,
      inactiveIcon: Icons.travel_explore_outlined,
      label: 'Portal Karir',
    ),
    _NavItem(
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
      label: 'Profil',
    ),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        key: const ValueKey(0),
        onNavigateTab: (index) => _onTabTapped(index),
      ),
      const FreshGradPrepScreen(key: ValueKey(1)),
      const JobListScreen(key: ValueKey(2)),
      const JobDiscoveryScreen(key: ValueKey(3)),
      const SettingsScreen(key: ValueKey(4)),
    ];

    _scaleControllers = List.generate(
      _items.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 140),
      ),
    );
    _scaleAnimations = _scaleControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.86), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 0.86, end: 1.05), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }).toList();

    _scaleControllers[_currentIndex].value = 1.0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowAppTour());
  }

  @override
  void dispose() {
    for (var ctrl in _scaleControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _checkAndShowTabWelcomeScreen(int index) async {
    if (!mounted || _isAppTourVisible) return;
    if (index == 1) {
      final seen = await PrefsService.isCareerPrepIntroSeen();
      if (!seen && mounted && !_isAppTourVisible) {
        Navigator.push(
          context,
          WelcomeScreenRoute(child: const CareerPrepWelcomeScreen()),
        );
      }
    } else if (index == 2) {
      final seen = await PrefsService.isJobListIntroSeen();
      if (!seen && mounted && !_isAppTourVisible) {
        Navigator.push(
          context,
          WelcomeScreenRoute(child: const JobListWelcomeScreen()),
        );
      }
    } else if (index == 3) {
      final seen = await PrefsService.isDiscoveryIntroSeen();
      if (!seen && mounted && !_isAppTourVisible) {
        Navigator.push(
          context,
          WelcomeScreenRoute(child: const DiscoveryWelcomeScreen()),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) {
        _scaleControllers[index].forward(from: 0.0);
      }
      setState(() {
        _currentIndex = index;
      });
      if (!_isAppTourVisible) {
        _checkAndShowTabWelcomeScreen(index);
      }
      if (index == 0) _maybeShowAppTour();
    }
  }

  Future<void> _maybeShowAppTour() async {
    if (!mounted || _isAppTourVisible) return;
    final seen = await PrefsService.isAppTourSeen();
    if (!mounted || seen || _isAppTourVisible) return;
    setState(() => _isAppTourVisible = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onTabTapped(0);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          HapticFeedback.lightImpact();
          AppleToast.info(context, 'Tekan sekali lagi untuk keluar');
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Every tab stays mounted so its scroll, search, filters, and
            // expanded-card state survive. Switching cross-fades for 0.1 s;
            // there is deliberately no slide or positional movement.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: SizedBox(
                    width: math.min(constraints.maxWidth, 840),
                    height: constraints.maxHeight,
                    child: _FadeTabStack(
                      activeIndex: _currentIndex,
                      children: _screens,
                    ),
                  ),
                ),
              ),
            ),

            // Floating 5-Item Capsule Navbar (Safe for Android 3-button & iOS Home Bar)
            Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: math.min(constraints.maxWidth, 720),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: AppLayoutMetrics.floatingNavigationBottom(
                        context,
                      ),
                      left: 20,
                      right: 20,
                    ),
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF202024)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF38383E)
                              : const Color(0xFFE5E0D5),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(_items.length, (index) {
                          final item = _items[index];
                          final isSelected = _currentIndex == index;
                          final hasNotices =
                              index == 3 &&
                              ref
                                  .watch(jobProvider)
                                  .jobs
                                  .any(
                                    (j) =>
                                        j.interviewDate != null ||
                                        j.status == 'Offering' ||
                                        j.status == 'Tes / Psikotes' ||
                                        j.status.startsWith('Interview'),
                                  );

                          return Semantics(
                            button: true,
                            selected: isSelected,
                            label: item.label,
                            child: Tooltip(
                              message: item.label,
                              child: GestureDetector(
                                onTap: () => _onTabTapped(index),
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox.square(
                                  dimension: 48,
                                  child: ScaleTransition(
                                    scale: _scaleAnimations[index],
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      margin: EdgeInsets.all(
                                        isSelected ? 0 : 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1C1C1E))
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.16
                                                            : 0.22,
                                                      ),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          alignment: Alignment.center,
                                          children: [
                                            Icon(
                                              isSelected
                                                  ? item.activeIcon
                                                  : item.inactiveIcon,
                                              color: isSelected
                                                  ? (isDark
                                                        ? const Color(
                                                            0xFF1C1C1E,
                                                          )
                                                        : Colors.white)
                                                  : (isDark
                                                        ? const Color(
                                                            0xFFAEAEB2,
                                                          )
                                                        : const Color(
                                                            0xFF8E8E93,
                                                          )),
                                              size: isSelected ? 22 : 21,
                                            ),
                                            if (hasNotices && !isSelected)
                                              Positioned(
                                                top: -2,
                                                right: -2,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFFFF453A,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isAppTourVisible)
              AppTourOverlay(
                onSwitchTab: _onTabTapped,
                onFinish: () {
                  if (mounted) setState(() => _isAppTourVisible = false);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FadeTabStack extends StatefulWidget {
  final int activeIndex;
  final List<Widget> children;

  const _FadeTabStack({required this.activeIndex, required this.children});

  @override
  State<_FadeTabStack> createState() => _FadeTabStackState();
}

class _FadeTabStackState extends State<_FadeTabStack>
    with TickerProviderStateMixin {
  late final List<AnimationController> _fadeControllers;
  late final List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _fadeControllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
        value: index == widget.activeIndex ? 1.0 : 0.0,
      ),
    );
    _fadeAnimations = _fadeControllers.map((ctrl) {
      return CurvedAnimation(
        parent: ctrl,
        curve: Curves.easeInOutCubic,
      );
    }).toList();
  }

  @override
  void didUpdateWidget(covariant _FadeTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      final prev = oldWidget.activeIndex;
      final next = widget.activeIndex;

      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _fadeControllers[prev].value = 0.0;
        _fadeControllers[next].value = 1.0;
      } else {
        _fadeControllers[prev].animateTo(0.0, curve: Curves.easeIn);
        _fadeControllers[next].animateTo(1.0, curve: Curves.easeOut);
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _fadeControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (index) {
        final isActive = index == widget.activeIndex;
        return AnimatedBuilder(
          animation: _fadeAnimations[index],
          builder: (context, child) {
            final val = _fadeAnimations[index].value;
            final isVisible = val > 0.0 || isActive;

            return Offstage(
              offstage: !isVisible,
              child: IgnorePointer(
                ignoring: !isActive,
                child: ExcludeSemantics(
                  excluding: !isActive,
                  child: HeroMode(
                    enabled: isActive,
                    child: TickerMode(
                      enabled: isVisible,
                      child: Opacity(
                        opacity: val.clamp(0.0, 1.0),
                        child: RepaintBoundary(
                          child: widget.children[index],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
