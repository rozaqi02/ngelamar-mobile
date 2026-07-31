import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/job_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'jobs/job_list_screen.dart';
import 'settings/settings_screen.dart';
import 'prep/fresh_grad_prep_screen.dart';

// Data model tiap item navbar
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

/// Apple iOS 26 Liquid Glass Dynamic Capsule Navigation Bar.
/// - Pill sliding dengan spring animation via TweenAnimationBuilder
/// - Icon 24pt + label 10pt sesuai Apple HIG SF Pro
/// - Tidak ada teks overflow: SizedBox fixed width per item
/// - Specular glass highlight strip di bagian atas navbar
/// - Haptic-like scale bounce saat tap
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;

  // Controller untuk bounce scale per item
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  static const _items = [
    _NavItem(
      activeIcon: CupertinoIcons.house_fill,
      inactiveIcon: CupertinoIcons.house,
      label: 'Beranda',
    ),
    _NavItem(
      activeIcon: CupertinoIcons.briefcase_fill,
      inactiveIcon: CupertinoIcons.briefcase,
      label: 'Lamaran',
    ),
    _NavItem(
      activeIcon: CupertinoIcons.checkmark_seal_fill,
      inactiveIcon: CupertinoIcons.checkmark_seal,
      label: 'Persiapan',
    ),
    _NavItem(
      activeIcon: CupertinoIcons.gear_alt_fill,
      inactiveIcon: CupertinoIcons.gear_alt,
      label: 'Pengaturan',
    ),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(key: ValueKey(0)),
    JobListScreen(key: ValueKey(1)),
    FreshGradPrepScreen(key: ValueKey(2)),
    SettingsScreen(key: ValueKey(3)),
  ];

  @override
  void initState() {
    super.initState();
    _scaleControllers = List.generate(
      _items.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 140),
      ),
    );
    _scaleAnimations = _scaleControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(
            tween: Tween(begin: 1.0, end: 0.82), weight: 40),
        TweenSequenceItem(
            tween: Tween(begin: 0.82, end: 1.08), weight: 40),
        TweenSequenceItem(
            tween: Tween(begin: 1.08, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _scaleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    _scaleControllers[index].forward(from: 0);
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
    final goingRight = _currentIndex > _previousIndex;

    // Navbar pill: tinggi tetap 64, padding horizontal 10, vertical 6
    // Setiap item mendapat lebar yang sama persis via LayoutBuilder
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Animated screen transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 230),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final inOff =
                  goingRight ? const Offset(0.025, 0) : const Offset(-0.025, 0);
              final outOff =
                  goingRight ? const Offset(-0.025, 0) : const Offset(0.025, 0);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: child.key == ValueKey(_currentIndex) ? inOff : outOff,
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _screens[_currentIndex],
          ),

          // Bottom Navbar - Apple Liquid Glass Capsule
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: bottomInset > 0 ? bottomInset + 8 : 20,
              ),
              child: RepaintBoundary(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Lebar total container
                    final navWidth = constraints.maxWidth;
                    // Lebar tiap item sama rata
                    final itemW = navWidth / _items.length;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            // Dual layer glass: translucent bg + specular shine
                            color: isDark
                                ? const Color(0xD4141416)
                                : const Color(0xEEF8F8FA),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : Colors.black.withValues(alpha: 0.07),
                              width: AppTheme.borderHairline,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isDark ? 0.55 : 0.10),
                                blurRadius: 32,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isDark ? 0.20 : 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // -- Glass specular highlight strip (top rim) --
                              Positioned(
                                top: 0,
                                left: 12,
                                right: 12,
                                height: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        Colors.white.withValues(
                                            alpha: isDark ? 0.22 : 0.55),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // -- Liquid Sliding Active Pill --
                              // TweenAnimationBuilder untuk spring-like smooth interpolasi
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: _previousIndex.toDouble(),
                                  end: _currentIndex.toDouble(),
                                ),
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                                builder: (context, animVal, _) {
                                  return Positioned(
                                    left: animVal * itemW + 5,
                                    top: 5,
                                    bottom: 5,
                                    width: itemW - 10,
                                    child: _buildActivePill(isDark),
                                  );
                                },
                              ),

                              // -- Tab Items Row --
                              Row(
                                children: List.generate(
                                  _items.length,
                                  (i) => SizedBox(
                                    width: itemW,
                                    height: 64,
                                    child: _buildTabItem(i, isDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pill aktif dengan gradient putih lembut + subtle shadow biru
  Widget _buildActivePill(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF2C2C2F), Color(0xFF232325)]
              : const [Color(0xFFFFFFFF), Color(0xFFF4F4F8)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
          width: AppTheme.borderHairline,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue)
                .withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  /// Satu item tab: icon 22pt + label 10pt, terkurung dalam SizedBox fixed
  Widget _buildTabItem(int index, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue;
    final inactiveColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF6E6E73);
    final item = _items[index];

    return GestureDetector(
      onTap: () => _onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimations[index].value,
            child: child,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Icon dengan AnimatedSwitcher untuk swap aktif/tidak aktif
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.inactiveIcon,
                key: ValueKey('${index}_$isSelected'),
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            // Label dengan lebar terbatas agar tidak overflow
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
                letterSpacing: -0.15,
                height: 1.0,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
