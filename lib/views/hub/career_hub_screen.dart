import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/career_context.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_back_policy.dart';
import '../discovery/job_discovery_screen.dart';
import '../../widgets/app_layout_metrics.dart';
import '../../widgets/app_tour_overlay.dart';
import '../../widgets/header_help_button.dart';
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
  bool _showTour = false;

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
    final pageBackground = AppTheme.getBackground(context);
    final headerHeight = topInset + 198.0;

    return AppBackScope(
      child: Scaffold(
        backgroundColor: pageBackground,
        body: Stack(
          children: [
            // Content stays mounted while the segmented switcher changes page.
            Positioned.fill(
              top: headerHeight,
              child: TourAnchor(
                id: 'hub_body',
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (value) {
                    if (_section == value) return;
                    HapticFeedback.selectionClick();
                    setState(() => _section = value);
                  },
                  children: [
                    JobDiscoveryScreen(embedded: true, onHelp: _startTour),
                    FreshGradPrepScreen(
                      embedded: true,
                      careerContext: widget.careerContext,
                      onHelp: _startTour,
                    ),
                  ],
                ),
              ),
            ),

            // Dedicated workspace header. The hero from Kalender lands on the
            // mosaic mark, making the entry feel like one connected surface.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: pageBackground,
                padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TourAnchor(
                      id: 'hub_header',
                      child: Row(
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
                                          ? const Color(0xFF383842)
                                          : const Color(0xFFE5E0D5),
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.04,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
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
                          const Spacer(),
                          Hero(
                            tag: 'career_hub_launcher',
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF383842)
                                      : const Color(0xFFE5E0D5),
                                  width: 1.4,
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
                          const SizedBox(width: 8),
                          HeaderHelpButton(
                            onTap: _startTour,
                            semanticLabel: 'Buka tutorial Ruang Karier',
                            iconColor: const Color(0xFF5C44E4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'RUANG\nKARIER',
                      style: TextStyle(
                        color: AppTheme.getTextPrimary(context),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.15,
                        height: 0.99,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TourAnchor(
                      id: 'hub_switcher',
                      child: _buildSwitcher(isDark, surface),
                    ),
                  ],
                ),
              ),
            ),
            if (_showTour)
              AppTourOverlay(
                tabIndex: 5,
                onFinish: () {
                  if (mounted) setState(() => _showTour = false);
                },
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
              label: 'Portal Loker',
              icon: Icons.travel_explore_rounded,
              onTap: () => _select(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _HubSegment(
              selected: _section == 1,
              label: 'Siapkan Karir',
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
  }

  void _startTour() {
    HapticFeedback.selectionClick();
    setState(() => _showTour = true);
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
    final activeBg = isDark ? const Color(0xFF5C44E4) : const Color(0xFF19191B);
    final activeText = Colors.white;

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
