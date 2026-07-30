import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/job_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'jobs/job_list_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(key: ValueKey(0)),
    JobListScreen(key: ValueKey(1)),
    SettingsScreen(key: ValueKey(2)),
  ];

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(jobProvider).isDarkMode;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    // Directional slide: going right → slide from right; going left → slide from left
    final goingRight = _currentIndex > _previousIndex;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.background : AppTheme.lBackground,
      body: Stack(
        children: [
          // Directional animated tab switch
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final inOffset  = goingRight ? const Offset(0.04, 0) : const Offset(-0.04, 0);
              final outOffset = goingRight ? const Offset(-0.04, 0) : const Offset(0.04, 0);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: child.key == ValueKey(_currentIndex)
                        ? inOffset
                        : outOffset,
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _screens[_currentIndex],
          ),

          // Apple iOS Floating Tab Bar Dock
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // Respect Android system navigation bar height
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: bottomInset > 0 ? bottomInset + 8 : 24,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    height: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, CupertinoIcons.square_grid_2x2_fill,
                            CupertinoIcons.square_grid_2x2, 'Beranda'),
                        _buildNavItem(1, CupertinoIcons.briefcase_fill,
                            CupertinoIcons.briefcase, 'Lamaran'),
                        _buildNavItem(2, CupertinoIcons.gear_alt_fill,
                            CupertinoIcons.gear_alt, 'Pengaturan'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: isSelected
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 0.8,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected
                    ? AppTheme.systemBlue
                    : AppTheme.textSecondary,
                size: 22,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Row(
                      children: [
                        const SizedBox(width: 7),
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppTheme.systemBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
