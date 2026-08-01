import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.08), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 20),
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
    HapticFeedback.selectionClick();
    _scaleControllers[index].forward(from: 0);
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(jobProvider).isDarkMode;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bg = AppTheme.getBackground(context);

    // Navbar pill: tinggi tetap 64, padding horizontal 10, vertical 6
    // Setiap item mendapat lebar yang sama persis via LayoutBuilder
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),

          // Bottom Navbar - Apple Liquid Glass Capsule
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: bottomInset > 0 ? bottomInset + 8 : 20,
              ),
              child: RepaintBoundary(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Lebar total container
                    final navWidth = constraints.maxWidth;
                    // Lebar tiap item sama rata
                    final itemW = navWidth / _items.length;
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final showLabels = itemW >= 72 && textScale <= 1.3;
                    final navHeight = showLabels ? 66.0 : 56.0;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          height: navHeight,
                          decoration: BoxDecoration(
                            // Dual layer glass: translucent bg + specular shine
                            color: isDark
                                ? const Color(0xDC161618)
                                : const Color(0xF2F9F9FB),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: AppTheme.borderHairline,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.45 : 0.08,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.15 : 0.03,
                                ),
                                blurRadius: 6,
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
                                left: 14,
                                right: 14,
                                height: 1.2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        Colors.white.withValues(
                                          alpha: isDark ? 0.28 : 0.65,
                                        ),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // -- Liquid Sliding Active Pill --
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 380),
                                curve: Curves.easeOutCubic,
                                left: _currentIndex * itemW + 4,
                                top: 4,
                                bottom: 4,
                                width: itemW - 8,
                                child: _buildActivePill(isDark),
                              ),

                              // -- Tab Items Row --
                              Row(
                                children: List.generate(
                                  _items.length,
                                  (i) => SizedBox(
                                    width: itemW,
                                    height: navHeight,
                                    child: _buildTabItem(
                                      i,
                                      isDark,
                                      showLabel: showLabels,
                                    ),
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
  Widget _buildTabItem(int index, bool isDark, {required bool showLabel}) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue;
    final inactiveColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF6E6E73);
    final item = _items[index];

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: GestureDetector(
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
                if (showLabel) ...[
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      color: isSelected ? activeColor : inactiveColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 10,
                      letterSpacing: -0.15,
                      height: 1.0,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
