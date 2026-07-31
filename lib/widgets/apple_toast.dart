import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Apple iOS 18 Dynamic Capsule Toast Notification (Bottom Floating Dock style).
/// Displays a sleek glassmorphic capsule above the bottom navigation bar
/// with rich icon badges, titles, subtitles, and interactive action buttons.
class AppleToast {
  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    IconData? icon,
    Color? color,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    final overlay = Overlay.of(context);
    final isDark = AppTheme.isDark(context);
    final toastColor = color ?? AppTheme.systemGreen;

    late OverlayEntry entry;
    final controller = _ToastAnimController();

    entry = OverlayEntry(
      builder: (_) => _AppleToastWidget(
        message: message,
        subtitle: subtitle,
        icon: icon ?? CupertinoIcons.checkmark_alt,
        color: toastColor,
        isDark: isDark,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        controller: controller,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }

  /// Shortcut for success toast with optional subtitle & action
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

class _ToastAnimController {
  VoidCallback? dismiss;
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
  final _ToastAnimController controller;
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
    required this.controller,
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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );

    // Slide up from bottom (+1.2 -> 0)
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    widget.controller.dismiss = _dismiss;

    _animController.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _animController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final txtPri = widget.isDark ? Colors.white : Colors.black;
    final txtSec = widget.isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);

    return Positioned(
      bottom: bottomInset + 76, // Floating above bottom navbar dock
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy > 100) _dismiss();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF1E1E20).withValues(alpha: 0.90)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                      width: AppTheme.borderHairline,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                            alpha: widget.isDark ? 0.45 : 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Glowing circular icon badge
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon,
                            color: widget.color, size: 18),
                      ),
                      const SizedBox(width: 12),

                      // Text message & optional subtitle
                      Expanded(
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

                      // Optional Action Button (e.g. "Lihat", "Buka", "Urungkan")
                      if (widget.actionLabel != null && widget.onAction != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _dismiss();
                            widget.onAction?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              widget.actionLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
    );
  }
}
