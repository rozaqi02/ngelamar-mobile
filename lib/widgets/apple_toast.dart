import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Data class representing a queued toast item.
class _ToastItem {
  final BuildContext context;
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;

  _ToastItem({
    required this.context,
    required this.message,
    this.subtitle,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.onAction,
    required this.duration,
  });
}

/// Apple iOS Dynamic Island & Floating Glass Capsule Toast Notification System.
/// Provides compact, high-precision floating toast notifications with queuing support,
/// spring animations, and native Apple HIG design aesthetics.
class AppleToast {
  static final List<_ToastItem> _queue = [];
  static bool _isShowing = false;

  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    IconData? icon,
    Color? color,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final item = _ToastItem(
      context: context,
      message: message,
      subtitle: subtitle,
      icon: icon ?? CupertinoIcons.checkmark_alt,
      color: color ?? AppTheme.systemGreen,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );

    _queue.add(item);
    _processQueue();
  }

  static void _processQueue() {
    if (_isShowing || _queue.isEmpty) return;

    _isShowing = true;
    final item = _queue.removeAt(0);

    final overlay = Overlay.maybeOf(item.context);
    if (overlay == null) {
      _isShowing = false;
      _processQueue();
      return;
    }

    final isDark = AppTheme.isDark(item.context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _AppleToastWidget(
        message: item.message,
        subtitle: item.subtitle,
        icon: item.icon,
        color: item.color,
        isDark: isDark,
        actionLabel: item.actionLabel,
        onAction: item.onAction,
        duration: item.duration,
        onDismiss: () {
          entry.remove();
          _isShowing = false;
          Future.delayed(const Duration(milliseconds: 100), _processQueue);
        },
      ),
    );

    overlay.insert(entry);
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
      icon: CupertinoIcons.checkmark_circle_fill,
      color: AppTheme.systemGreen,
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
      icon: CupertinoIcons.xmark_circle_fill,
      color: AppTheme.systemRed,
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
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      color: AppTheme.systemOrange,
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
      icon: CupertinoIcons.info_circle_fill,
      color: AppTheme.systemBlue,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _AppleToastWidget extends StatefulWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismiss;

  const _AppleToastWidget({
    required this.message,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_AppleToastWidget> createState() => _AppleToastWidgetState();
}

class _AppleToastWidgetState extends State<_AppleToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    if (!mounted) return;
    _animController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final txtPri = widget.isDark ? Colors.white : const Color(0xFF1C1C1E);
    final txtSec = widget.isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);

    return Positioned(
      bottom: bottomInset + 78,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy > 50) _dismiss();
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? const Color(0xF21C1C1E)
                              : const Color(0xF5FFFFFF),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: widget.isDark
                                ? Colors.white.withValues(alpha: 0.16)
                                : Colors.black.withValues(alpha: 0.08),
                            width: AppTheme.borderHairline,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: widget.isDark ? 0.45 : 0.10),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon Badge
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.color,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Text message & subtitle
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.message,
                                    style: TextStyle(
                                      color: txtPri,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.subtitle != null) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      widget.subtitle!,
                                      style: TextStyle(
                                        color: txtSec,
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

                            // Glass Action Button
                            if (widget.actionLabel != null &&
                                widget.onAction != null) ...[
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  _dismiss();
                                  widget.onAction?.call();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: widget.color.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: widget.color.withValues(alpha: 0.3),
                                      width: AppTheme.borderHairline,
                                    ),
                                  ),
                                  child: Text(
                                    widget.actionLabel!,
                                    style: TextStyle(
                                      color: widget.color,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.1,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
