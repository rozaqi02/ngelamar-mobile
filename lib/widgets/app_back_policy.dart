import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_toast.dart';

/// Centralized back navigation policy for Ngelamar.
///
/// Enforces:
/// 1. Root dock tabs never display back buttons.
/// 2. Back gestures in secondary tabs (1..4) deterministically navigate back to Tab 0 (Beranda).
/// 3. Back gesture on Tab 0 requires a double-tap confirmation within 2 seconds before exiting.
/// 4. Child routes (e.g. JobDetail, AddEditJob) pop cleanly back to the parent view
///    while preserving tab index, scroll offset, and filter state.
abstract final class AppBackPolicy {
  static const Duration exitDoubleTapThreshold = Duration(seconds: 2);
  static const String exitConfirmationMessage =
      'Tekan sekali lagi untuk keluar aplikasi';

  /// Determines if an app-bar back button should be visible.
  /// Root dock tabs strictly return false (GR-01 / WP-02).
  static bool shouldShowAppBarBackButton({required bool isRootShellTab}) {
    return !isRootShellTab;
  }

  /// Handles system back navigation in the root shell ([MainNavigation]).
  ///
  /// Returns `true` if the app should exit, or `false` if the event was consumed.
  static bool handleRootBack({
    required BuildContext context,
    required int currentIndex,
    required ValueChanged<int> onSwitchTab,
    required DateTime? lastBackPressTime,
    required ValueChanged<DateTime> onUpdateBackPressTime,
  }) {
    // 1. Secondary tabs deterministically return to Tab 0 (Home) first.
    if (currentIndex != 0) {
      onSwitchTab(0);
      return false;
    }

    // 2. On Tab 0, require double-tap within threshold before exiting.
    final now = DateTime.now();
    if (lastBackPressTime == null ||
        now.difference(lastBackPressTime) > exitDoubleTapThreshold) {
      onUpdateBackPressTime(now);
      AppToast.info(context, exitConfirmationMessage);
      return false;
    }

    // 3. Second back tap confirmed -> Exit cleanly via platform channel.
    SystemNavigator.pop();
    return true;
  }

  /// Handles back navigation for child screens with optional discard confirmation.
  static Future<bool> handleChildBack({
    required BuildContext context,
    Future<bool> Function()? onConfirmDiscard,
  }) async {
    if (onConfirmDiscard != null) {
      final shouldDiscard = await onConfirmDiscard();
      if (!shouldDiscard) return false;
    }

    if (context.mounted) {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
        return true;
      }
    }
    return false;
  }
}

/// Standardized PopScope wrapper widget that integrates [AppBackPolicy].
class AppBackScope extends StatelessWidget {
  final Widget child;
  final bool isRootShell;
  final int? currentTabIndex;
  final ValueChanged<int>? onSwitchTab;
  final DateTime? lastBackPressTime;
  final ValueChanged<DateTime>? onUpdateBackPressTime;
  final Future<bool> Function()? onConfirmDiscard;
  final VoidCallback? onPop;

  const AppBackScope({
    super.key,
    required this.child,
    this.isRootShell = false,
    this.currentTabIndex,
    this.onSwitchTab,
    this.lastBackPressTime,
    this.onUpdateBackPressTime,
    this.onConfirmDiscard,
    this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    final canDirectPop =
        !isRootShell && onConfirmDiscard == null && onPop == null;

    return PopScope(
      canPop: canDirectPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (isRootShell &&
            currentTabIndex != null &&
            onSwitchTab != null &&
            onUpdateBackPressTime != null) {
          AppBackPolicy.handleRootBack(
            context: context,
            currentIndex: currentTabIndex!,
            onSwitchTab: onSwitchTab!,
            lastBackPressTime: lastBackPressTime,
            onUpdateBackPressTime: onUpdateBackPressTime!,
          );
          return;
        }

        if (onPop != null) {
          onPop!();
          return;
        }

        await AppBackPolicy.handleChildBack(
          context: context,
          onConfirmDiscard: onConfirmDiscard,
        );
      },
      child: child,
    );
  }
}
