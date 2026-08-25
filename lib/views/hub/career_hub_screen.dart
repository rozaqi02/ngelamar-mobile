import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/welcome_screen_route.dart';
import '../discovery/discovery_welcome_screen.dart';
import '../discovery/job_discovery_screen.dart';
import '../prep/career_prep_welcome_screen.dart';
import '../prep/fresh_grad_prep_screen.dart';

/// A continuous, swipeable home for finding and preparing for opportunities.
class CareerHubScreen extends StatefulWidget {
  const CareerHubScreen({super.key});

  @override
  State<CareerHubScreen> createState() => _CareerHubScreenState();
}

class _CareerHubScreenState extends State<CareerHubScreen> {
  int _section = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final surface = isDark ? const Color(0xFF1D1D22) : Colors.white;

    final topInset = MediaQuery.of(context).padding.top;
    final greenBackground = isDark
        ? const Color(0xFF0F1B14)
        : const Color(0xFFE8F5E9);
    final switcherHeight = topInset + 64.0;

    return Scaffold(
      backgroundColor: greenBackground,
      body: Stack(
        children: [
          // Content PageView
          Positioned.fill(
            top: switcherHeight,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (value) {
                if (_section == value) return;
                HapticFeedback.selectionClick();
                setState(() => _section = value);
                unawaited(_showWelcomeIfNeeded(value));
              },
              children: const [
                JobDiscoveryScreen(embedded: true),
                FreshGradPrepScreen(embedded: true),
              ],
            ),
          ),

          // Floating Switcher Bar (Shadow never clipped)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: greenBackground,
              padding: EdgeInsets.fromLTRB(16, topInset + 6, 16, 10),
              child: _buildSwitcher(isDark, surface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcher(bool isDark, Color surface) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF34343A) : const Color(0xFFE4E0D7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _HubSegment(
              selected: _section == 0,
              label: 'Portal Loker Resmi',
              icon: Icons.travel_explore_rounded,
              onTap: () => _select(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _HubSegment(
              selected: _section == 1,
              label: 'Persiapan Karirku',
              icon: Icons.school_rounded,
              onTap: () => _select(1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _select(int value) async {
    if (_section == value) return;
    setState(() => _section = value);
    await _pageController.animateToPage(
      value,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubicEmphasized,
    );
    await _showWelcomeIfNeeded(value);
  }

  Future<void> _showWelcomeIfNeeded(int value) async {
    final seen = value == 0
        ? await PrefsService.isDiscoveryIntroSeen()
        : await PrefsService.isCareerPrepIntroSeen();
    if (!mounted || seen) return;
    Navigator.push(
      context,
      WelcomeScreenRoute(
        child: value == 0
            ? const DiscoveryWelcomeScreen()
            : const CareerPrepWelcomeScreen(),
      ),
    );
  }
}

class _HubSegment extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HubSegment({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final activeBg = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final activeText = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return FluidBounceButton(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      scaleFactor: 0.985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: double.infinity,
        decoration: BoxDecoration(
          color: selected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.20 : 0.18,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? activeText
                  : (isDark ? Colors.white60 : const Color(0xFF65656A)),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? activeText
                      : (isDark ? Colors.white60 : const Color(0xFF65656A)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
