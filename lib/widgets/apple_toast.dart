import 'package:flutter/material.dart';
import 'app_toast.dart';

/// Legacy AppleToast wrapper.
/// Secara otomatis mengarahkan ke implementasi AppToast yang baru, native, dan mulus.
class AppleToast {
  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    IconData? icon,
    Color? color,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    AppToast.show(
      context,
      message: message,
      subtitle: subtitle,
      icon: icon ?? Icons.info_outline_rounded,
      color: color ?? const Color(0xFF3884F5),
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void success(
    BuildContext context,
    String message, {
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppToast.success(context, message, subtitle: subtitle, actionLabel: actionLabel, onAction: onAction);
  }

  static void error(
    BuildContext context,
    String message, {
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppToast.error(context, message, subtitle: subtitle, actionLabel: actionLabel, onAction: onAction);
  }

  static void warning(
    BuildContext context,
    String message, {
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppToast.warning(context, message, subtitle: subtitle, actionLabel: actionLabel, onAction: onAction);
  }

  static void info(
    BuildContext context,
    String message, {
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppToast.info(context, message, subtitle: subtitle, actionLabel: actionLabel, onAction: onAction);
  }
}
