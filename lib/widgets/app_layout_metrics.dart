import 'package:flutter/widgets.dart';

/// Screen layout type for calculating adaptive scaffold insets.
enum ScaffoldInsetMode { rootTab, fullScreenRoute, sheet, modal }

/// Centralized layout metrics and system insets for Ngelamar.
///
/// Ensures:
/// 1. System insets (status bar, notch, gesture bar, keyboard) are consumed
///    predictably without double-padding on Android edge-to-edge or Web.
/// 2. Dock never collides with Android gesture bar or 3-button navigation.
/// 3. All 5 root tabs share identical header baseline alignment.
abstract final class AppLayoutMetrics {
  // The dock body remains 64 px; this reserves the raised primary action too.
  static const double floatingNavigationHeight = 94;
  static const double floatingNavigationGap = 24;

  static double floatingNavigationBottom(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom > 0 ? safeBottom + 12 : 24;
  }

  /// Total top space required from screen top to clear notches, Dynamic Island,
  /// status bars, as well as web/desktop responsive viewport emulators.
  static double headerTopPadding(BuildContext context, {double extra = 14.0}) {
    final safeTop = MediaQuery.paddingOf(context).top;
    if (safeTop > 0) {
      return safeTop + extra;
    }
    // Fallback for Web/DevTools responsive emulators where safeTop == 0.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobileView = screenWidth < 600;
    return (isMobileView ? 48.0 : 16.0) + extra;
  }

  /// Spacing when already placed inside a [SafeArea(bottom: false, child: ...)].
  /// On real devices (safeTop > 0), [SafeArea] already applied the notch inset,
  /// so only [extra] breathing room is needed.
  /// On Web/DevTools emulators (safeTop == 0), [SafeArea] adds 0, so we simulate
  /// the Dynamic Island / notch space (~48px).
  static double headerTopInsideSafeArea(
    BuildContext context, {
    double extra = 14.0,
  }) {
    final safeTop = MediaQuery.paddingOf(context).top;
    if (safeTop > 0) {
      return extra;
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobileView = screenWidth < 600;
    return (isMobileView ? 48.0 : 16.0) + extra;
  }

  /// Bottom space required after scrollable content so it stays tappable above
  /// the floating navigation, including on devices with a gesture indicator.
  static double contentBottomClearance(BuildContext context) =>
      floatingNavigationBottom(context) +
      floatingNavigationHeight +
      floatingNavigationGap;
}

/// Resolved system inset values for consistent page scaffolds.
class AppScaffoldInsets {
  final double topHeader;
  final double bottomDock;
  final double contentBottom;
  final double keyboardInset;
  final bool hasNotch;
  final bool isMobile;
  final bool isTablet;

  const AppScaffoldInsets({
    required this.topHeader,
    required this.bottomDock,
    required this.contentBottom,
    required this.keyboardInset,
    required this.hasNotch,
    required this.isMobile,
    required this.isTablet,
  });

  /// Factory resolving insets based on context and mode.
  factory AppScaffoldInsets.of(
    BuildContext context, {
    ScaffoldInsetMode mode = ScaffoldInsetMode.rootTab,
    double extraHeaderPadding = 14.0,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final safeTop = mediaQuery.padding.top;
    final safeBottom = mediaQuery.padding.bottom;
    final keyboardBottom = mediaQuery.viewInsets.bottom;
    final screenWidth = mediaQuery.size.width;

    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600;
    final hasNotch = safeTop > 24;

    final double topHeader;
    final double bottomDock;
    final double contentBottom;

    switch (mode) {
      case ScaffoldInsetMode.rootTab:
        topHeader = AppLayoutMetrics.headerTopPadding(
          context,
          extra: extraHeaderPadding,
        );
        bottomDock = AppLayoutMetrics.floatingNavigationBottom(context);
        contentBottom = AppLayoutMetrics.contentBottomClearance(context);
        break;
      case ScaffoldInsetMode.fullScreenRoute:
        topHeader = AppLayoutMetrics.headerTopPadding(
          context,
          extra: extraHeaderPadding,
        );
        bottomDock = safeBottom > 0 ? safeBottom + 8 : 16;
        contentBottom = bottomDock + 80;
        break;
      case ScaffoldInsetMode.sheet:
      case ScaffoldInsetMode.modal:
        topHeader = extraHeaderPadding;
        bottomDock = safeBottom > 0 ? safeBottom + 12 : 20;
        contentBottom = bottomDock + keyboardBottom;
        break;
    }

    return AppScaffoldInsets(
      topHeader: topHeader,
      bottomDock: bottomDock,
      contentBottom: contentBottom,
      keyboardInset: keyboardBottom,
      hasNotch: hasNotch,
      isMobile: isMobile,
      isTablet: isTablet,
    );
  }
}
