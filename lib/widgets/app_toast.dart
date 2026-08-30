import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Clean, Solid, Zero-Fade Floating Capsule Toast Notification.
/// Slides up from the bottom with a subtle organic bounce, stays 100% solid,
/// and slides back down when finished.
class AppToast {
  static OverlayEntry? _activeEntry;
  static Timer? _activeTimer;

  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    IconData icon = Icons.info_outline_rounded,
    Color color = const Color(0xFF3884F5),
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    HapticFeedback.lightImpact();

    try {
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) return;

      // Clean up any existing toast immediately
      _dismissCurrentImmediately();

      late final OverlayEntry entry;
      final key = GlobalKey<_SolidBounceToastWidgetState>();

      entry = OverlayEntry(
        builder: (ctx) => _SolidBounceToastWidget(
          key: key,
          message: message,
          subtitle: subtitle,
          icon: icon,
          color: color,
          actionLabel: actionLabel,
          onAction: () {
            key.currentState?.dismiss();
            onAction?.call();
          },
          onDismissed: () {
            if (_activeEntry == entry) {
              entry.remove();
              _activeEntry = null;
            }
          },
        ),
      );

      _activeEntry = entry;
      overlay.insert(entry);

      _activeTimer = Timer(duration, () {
        key.currentState?.dismiss();
      });
    } catch (e) {
      debugPrint('AppToast error: $e');
    }
  }

  static void _dismissCurrentImmediately() {
    _activeTimer?.cancel();
    _activeTimer = null;
    if (_activeEntry != null) {
      _activeEntry!.remove();
      _activeEntry = null;
    }
  }

  static void dismiss() {
    _dismissCurrentImmediately();
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

class _SolidBounceToastWidget extends StatefulWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _SolidBounceToastWidget({
    super.key,
    required this.message,
    this.subtitle,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.onAction,
    required this.onDismissed,
  });

  @override
  State<_SolidBounceToastWidget> createState() =>
      _SolidBounceToastWidgetState();
}

class _SolidBounceToastWidgetState extends State<_SolidBounceToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 350),
    );

    // Slide from bottom with a slight organic bounce overshoot
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.8), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Cubic(0.18, 1.35, 0.35, 1.0),
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _controller.forward();
  }

  void dismiss() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;

    final double bottomOffset = bottomInset > 0
        ? bottomInset + 16.0
        : (bottomPadding > 0 ? bottomPadding + 76.0 : 84.0);

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 100) {
              dismiss();
            }
          },
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF19191B),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(widget.icon, color: widget.color, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.subtitle != null &&
                            widget.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
                    const SizedBox(width: 10),
                    Semantics(
                      button: true,
                      label: widget.actionLabel,
                      child: GestureDetector(
                        onTap: widget.onAction,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
