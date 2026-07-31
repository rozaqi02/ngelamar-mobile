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
    final bg = AppTheme.getBackground(context);

    // Directional slide animation
    final goingRight = _currentIndex > _previousIndex;

    return Scaffold(
      backgroundColor: bg,
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

          // Apple iOS Floating Tab Bar Dock (Light Mode aware)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: bottomInset > 0 ? bottomInset + 8 : 24,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 66,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C1E)
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.10),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.55)
                              : Colors.black.withValues(alpha: 0.10),
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
                            CupertinoIcons.square_grid_2x2, 'Beranda', isDark),
                        _buildNavItem(1, CupertinoIcons.briefcase_fill,
                            CupertinoIcons.briefcase, 'Lamaran', isDark),
                        _buildNavItem(2, CupertinoIcons.gear_alt_fill,
                            CupertinoIcons.gear_alt, 'Pengaturan', isDark),
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
      int index, IconData selectedIcon, IconData unselectedIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final blueColor = isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue;
    final txtSec = AppTheme.getTextSecondary(context);

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
          color: isSelected
              ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.08),
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
                color: isSelected ? blueColor : txtSec,
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
                          style: TextStyle(
                            color: blueColor,
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
