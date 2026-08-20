import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'discovery/job_discovery_screen.dart';
import 'jobs/job_list_screen.dart';
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

  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  static const _items = [
    _NavItem(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Beranda',
    ),
    _NavItem(
      activeIcon: Icons.explore_rounded,
      inactiveIcon: Icons.explore_outlined,
      label: 'Cari Loker',
    ),
    _NavItem(
      activeIcon: Icons.folder_rounded,
      inactiveIcon: Icons.folder_outlined,
      label: 'Lamaran',
    ),
    _NavItem(
      activeIcon: Icons.school_rounded,
      inactiveIcon: Icons.school_outlined,
      label: 'Persiapan',
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
      const JobDiscoveryScreen(key: ValueKey(1)),
      const JobListScreen(key: ValueKey(2)),
      const FreshGradPrepScreen(key: ValueKey(3)),
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
  }

  @override
  void dispose() {
    for (var c in _scaleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      _scaleControllers[index].forward(from: 0.0);
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Active Screen
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating 5-Item Capsule Navbar
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: const Color(0xFFE5E0D5),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isSelected = _currentIndex == index;

                    return GestureDetector(
                      onTap: () => _onTabTapped(index),
                      behavior: HitTestBehavior.opaque,
                      child: ScaleTransition(
                        scale: _scaleAnimations[index],
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.fastOutSlowIn,
                          width: isSelected ? 48 : 44,
                          height: isSelected ? 48 : 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1C1C1E)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.22),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              isSelected ? item.activeIcon : item.inactiveIcon,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF8E8E93),
                              size: isSelected ? 22 : 21,
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
    );
  }
}
