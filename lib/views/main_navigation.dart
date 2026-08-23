import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/prefs_service.dart';
import '../widgets/apple_toast.dart';
import '../widgets/welcome_screen_route.dart';
import 'dashboard/dashboard_screen.dart';
import 'discovery/discovery_welcome_screen.dart';
import 'hub/career_hub_screen.dart';
import 'jobs/job_list_screen.dart';
import 'jobs/job_list_welcome_screen.dart';
import 'notifications/notification_center_screen.dart';
import 'notifications/notification_welcome_screen.dart';
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
/// 2. Cari Loker (Glints & JobStreet Search Engine)
/// 3. Lamaran (Full Tracker & Status Management)
/// 4. Persiapan (Career Prep & Checklist)
/// 5. Profil (CRM Analytics & Settings)
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  static const _items = [
    _NavItem(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Beranda',
    ),
    _NavItem(
      activeIcon: Icons.travel_explore_rounded,
      inactiveIcon: Icons.travel_explore_outlined,
      label: 'Cari Lokerku',
    ),
    _NavItem(
      activeIcon: Icons.mail_rounded,
      inactiveIcon: Icons.mail_outline_rounded,
      label: 'Lamaran Saya',
    ),
    _NavItem(
      activeIcon: Icons.notifications_rounded,
      inactiveIcon: Icons.notifications_none_rounded,
      label: 'Kabar',
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
      const CareerHubScreen(key: ValueKey(1)),
      const JobListScreen(key: ValueKey(2)),
      const NotificationCenterScreen(key: ValueKey(3)),
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
  }

  @override
  void dispose() {
    for (var ctrl in _scaleControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _checkAndShowTabWelcomeScreen(int index) async {
    if (!mounted) return;
    if (index == 1) {
      final seen = await PrefsService.isDiscoveryIntroSeen();
      if (!seen && mounted) {
        Navigator.push(
          context,
          WelcomeScreenRoute(child: const DiscoveryWelcomeScreen()),
        );
      }
    } else if (index == 2) {
      final seen = await PrefsService.isJobListIntroSeen();
      if (!seen && mounted) {
        Navigator.push(
          context,
          WelcomeScreenRoute(child: const JobListWelcomeScreen()),
        );
      }
    } else if (index == 3) {
      final seen = await PrefsService.isNotificationIntroSeen();
      if (!seen && mounted) {
        Navigator.push(
          context,
          WelcomeScreenRoute(child: const NotificationWelcomeScreen()),
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
      _checkAndShowTabWelcomeScreen(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
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
            // Keep every tab alive so scroll, search, filter, and expanded-card
            // state are not lost when users move around the app.
            IndexedStack(
              index: _currentIndex,
              sizing: StackFit.expand,
              children: List.generate(
                _screens.length,
                (index) => TickerMode(
                  enabled: index == _currentIndex,
                  child: _screens[index],
                ),
              ),
            ),

            // Floating 5-Item Capsule Navbar (Safe for Android 3-button & iOS Home Bar)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: bottomInset > 0 ? bottomInset + 12 : 24,
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
                    color: isDark ? const Color(0xFF202024) : colors.surface,
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
                                  duration: const Duration(milliseconds: 180),
                                  margin: EdgeInsets.all(isSelected ? 0 : 2),
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
                                              color: Colors.black.withValues(
                                                alpha: isDark ? 0.16 : 0.22,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isSelected
                                          ? item.activeIcon
                                          : item.inactiveIcon,
                                      color: isSelected
                                          ? (isDark
                                                ? const Color(0xFF1C1C1E)
                                                : Colors.white)
                                          : (isDark
                                                ? const Color(0xFFAEAEB2)
                                                : const Color(0xFF8E8E93)),
                                      size: isSelected ? 22 : 21,
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
          ],
        ),
      ),
    );
  }
}
