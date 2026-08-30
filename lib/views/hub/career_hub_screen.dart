import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/prefs_service.dart';
import '../../models/career_context.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_back_policy.dart';
import '../../widgets/welcome_screen_route.dart';
import '../discovery/discovery_welcome_screen.dart';
import '../discovery/job_discovery_screen.dart';
import '../../widgets/app_layout_metrics.dart';
import '../prep/career_prep_welcome_screen.dart';
import '../prep/fresh_grad_prep_screen.dart';

/// A focused workspace for finding opportunities and preparing for them.
class CareerHubScreen extends StatefulWidget {
  final CareerContext? careerContext;
  final int initialSection;

  const CareerHubScreen({
    super.key,
    this.careerContext,
    this.initialSection = 0,
  });

  @override
  State<CareerHubScreen> createState() => _CareerHubScreenState();
}

class _CareerHubScreenState extends State<CareerHubScreen> {
  late int _section;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection.clamp(0, 1);
    _pageController = PageController(initialPage: _section);
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

    final topInset = AppLayoutMetrics.headerTopPadding(context, extra: 0);
    final greenBackground = isDark
        ? const Color(0xFF0F1B14)
        : const Color(0xFFE8F5E9);
    final headerHeight = topInset + 122.0;

    return AppBackScope(
      child: Scaffold(
        backgroundColor: greenBackground,
        body: Stack(
          children: [
            // Content stays mounted while the segmented switcher changes page.
            Positioned.fill(
              top: headerHeight,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) {
                  if (_section == value) return;
                  HapticFeedback.selectionClick();
                  setState(() => _section = value);
                  unawaited(_showWelcomeIfNeeded(value));
                },
                children: [
                  const JobDiscoveryScreen(embedded: true),
                  FreshGradPrepScreen(
                    embedded: true,
                    careerContext: widget.careerContext,
                  ),
                ],
              ),
            ),

            // Dedicated workspace header. The hero from Kalender lands on the
            // mosaic mark, making the entry feel like one connected surface.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: greenBackground,
                padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Kembali ke Kalender',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(21),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF34343A)
                                        : const Color(0xFFE4E0D7),
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppTheme.getTextPrimary(context),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Hero(
                          tag: 'career_hub_launcher',
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF25252B)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF34343A)
                                    : const Color(0xFFE4E0D7),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_mosaic_rounded,
                              color: isDark
                                  ? const Color(0xFFE3DCFF)
                                  : const Color(0xFF5C44E4),
                              size: 19,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'RUANG KARIER',
                            style: TextStyle(
                              color: AppTheme.getTextPrimary(context),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSwitcher(isDark, surface),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.18),
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
