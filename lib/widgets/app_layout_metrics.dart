import 'package:flutter/widgets.dart';

/// Shared geometry for pages that sit behind [MainNavigation]'s floating dock.
///
/// Keeping this in one place prevents the last card of one tab from being
/// obscured while another tab happens to have a different arbitrary padding.
abstract final class AppLayoutMetrics {
  static const double floatingNavigationHeight = 64;
  static const double floatingNavigationGap = 24;

  static double floatingNavigationBottom(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom > 0 ? safeBottom + 12 : 24;
  }

  /// Bottom space required after scrollable content so it stays tappable above
  /// the floating navigation, including on devices with a gesture indicator.
  static double contentBottomClearance(BuildContext context) =>
      floatingNavigationBottom(context) +
      floatingNavigationHeight +
      floatingNavigationGap;
}
