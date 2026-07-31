import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/job_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'jobs/job_list_screen.dart';
import 'settings/settings_screen.dart';

/// Apple iOS 26 Liquid Glass Dynamic Capsule Navigation Bar.
/// Features dual-layer glassmorphism blur, liquid sliding active indicator pill,
/// specular glass reflections, and micro-bounce touch feedback.
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
              final inOffset =
                  goingRight ? const Offset(0.04, 0) : const Offset(-0.04, 0);
              final outOffset =
                  goingRight ? const Offset(-0.04, 0) : const Offset(0.04, 0);

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

          // Apple iOS 26 Liquid Glass Dynamic Capsule Navbar
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: bottomInset > 0 ? bottomInset + 8 : 22,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(
                    height: 68,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF161618).withValues(alpha: 0.78)
                          : Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(36),
                      // Liquid Glass Specular Edge Highlight Gradient Border
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.black.withValues(alpha: 0.08),
                        width: AppTheme.borderHairline,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.60)
                              : Colors.black.withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                        // Inner Glass Highlight
                        BoxShadow(
                          color: (isDark ? Colors.white : AppTheme.systemBlue)
                              .withValues(alpha: 0.04),
                          blurRadius: 10,
                          spreadRadius: -2,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalW = constraints.maxWidth;
                        final itemW = totalW / 3;

                        return Stack(
                          children: [
                            // Liquid Sliding Active Pill Background
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              left: _currentIndex * itemW,
                              top: 0,
                              bottom: 0,
                              width: itemW,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            const Color(0xFF2C2C2E),
                                            const Color(0xFF3A3A3C)
                                          ]
                                        : [
                                            const Color(0xFFF2F2F7),
                                            const Color(0xFFE5E5EA)
                                          ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.06),
                                    width: AppTheme.borderHairline,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark
                                              ? AppTheme.systemBlue
                                              : AppTheme.lSystemBlue)
                                          .withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Interactive Tab Items
                            Row(
                              children: [
                                Expanded(
                                  child: _buildLiquidNavItem(
                                    0,
                                    CupertinoIcons.square_grid_2x2_fill,
                                    CupertinoIcons.square_grid_2x2,
                                    'Beranda',
                                    isDark,
                                  ),
                                ),
                                Expanded(
                                  child: _buildLiquidNavItem(
                                    1,
                                    CupertinoIcons.briefcase_fill,
                                    CupertinoIcons.briefcase,
                                    'Lamaran',
                                    isDark,
                                  ),
                                ),
                                Expanded(
                                  child: _buildLiquidNavItem(
                                    2,
                                    CupertinoIcons.gear_alt_fill,
                                    CupertinoIcons.gear_alt,
                                    'Pengaturan',
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
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

  Widget _buildLiquidNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
    bool isDark,
  ) {
    final isSelected = _currentIndex == index;
    final blueColor = isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue;
    final txtSec = AppTheme.getTextSecondary(context);

    return GestureDetector(
      onTap: () => _onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 12 : 8,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  color: isSelected ? blueColor : txtSec,
                  size: 21,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Row(
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              color: blueColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
