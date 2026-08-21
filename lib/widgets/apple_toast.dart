import 'dart:async';
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

/// Neo-Modern Floating Capsule Toast Notification System.
/// Features:
/// - Clean Material wrapper (Zero yellow text underlines)
/// - Crisp typography & micro-interactions
/// - Safe bottom navigation padding
/// - Dynamic Island / Floating pill design aesthetics
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
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    final item = _ToastItem(
      context: context,
      message: message,
      subtitle: subtitle,
      icon: icon ?? Icons.check_circle_rounded,
      color: color ?? const Color(0xFF10B981),
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
          Future.delayed(const Duration(milliseconds: 80), _processQueue);
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
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomInset > 0 ? bottomInset + 88 : 96,
      left: 18,
      right: 18,
      child: Material(
        type: MaterialType.transparency,
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
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF19191B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Color Icon Indicator
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                widget.icon,
                                color: widget.color,
                                size: 17,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Text Content (No yellow underlines)
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.none,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.72),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w400,
                                      decoration: TextDecoration.none,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Optional Action Button
                          if (widget.actionLabel != null && widget.onAction != null) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                _dismiss();
                                widget.onAction?.call();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  widget.actionLabel!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.none,
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
    );
  }
}
