import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern, Clean, Native Floating Capsule Toast Notification.
/// Uses native ScaffoldMessenger with zero overlay clutter, automatic keyboard avoidance,
/// fluid swipe-to-dismiss, and sleek modern typography.
class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    IconData icon = Icons.info_outline_rounded,
    Color color = const Color(0xFF3884F5),
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    HapticFeedback.lightImpact();

    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger.hideCurrentSnackBar();

      final bottomPadding = MediaQuery.of(context).padding.bottom;

      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF19191B),
          elevation: 8,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            bottomPadding > 0 ? bottomPadding + 70 : 80,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          duration: duration,
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('AppToast error: $e');
    }
  }

  /// Shortcut for success toast
  static void success(
    BuildContext context,
    String message, {
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF10B981),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shortcut for error toast
  static void error(
    BuildContext context,
    String message, {
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      icon: Icons.error_rounded,
      color: const Color(0xFFEF4444),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shortcut for warning toast
  static void warning(
    BuildContext context,
    String message, {
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFF59E0B),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shortcut for info toast
  static void info(
    BuildContext context,
    String message, {
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      icon: Icons.info_rounded,
      color: const Color(0xFF3B82F6),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
