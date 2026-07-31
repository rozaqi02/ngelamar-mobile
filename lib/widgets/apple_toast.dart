import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Apple-style toast notification that appears from the top of the screen.
/// Replaces Material SnackBar with an iOS-native notification banner.
class AppleToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? color,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    final overlay = Overlay.of(context);
    final isDark = AppTheme.isDark(context);
    final toastColor = color ?? AppTheme.systemGreen;

    late OverlayEntry entry;
    final controller = _ToastAnimController();

    entry = OverlayEntry(
      builder: (_) => _AppleToastWidget(
        message: message,
        icon: icon ?? CupertinoIcons.checkmark_circle_fill,
        color: toastColor,
        isDark: isDark,
        duration: duration,
        controller: controller,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }

  /// Shortcut for success toast
  static void success(BuildContext context, String message) {
    show(context,
        message: message,
        icon: CupertinoIcons.checkmark_circle_fill,
        color: AppTheme.systemGreen);
  }

  /// Shortcut for error toast
  static void error(BuildContext context, String message) {
    show(context,
        message: message,
        icon: CupertinoIcons.xmark_circle_fill,
        color: AppTheme.systemRed);
  }

  /// Shortcut for warning toast
  static void warning(BuildContext context, String message) {
    show(context,
        message: message,
        icon: CupertinoIcons.exclamationmark_circle_fill,
        color: AppTheme.systemOrange);
  }

  /// Shortcut for info toast
  static void info(BuildContext context, String message) {
    show(context,
        message: message,
        icon: CupertinoIcons.info_circle_fill,
        color: AppTheme.systemBlue);
  }
}

class _ToastAnimController {
  VoidCallback? dismiss;
}

class _AppleToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Duration duration;
  final _ToastAnimController controller;
  final VoidCallback onDismiss;

  const _AppleToastWidget({
    required this.message,
    required this.icon,
    required this.color,
    required this.isDark,
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
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
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

    // Enter
    _animController.forward();

    // Auto-dismiss
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
    final topPadding = MediaQuery.of(context).viewPadding.top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -100) _dismiss();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF2C2C2E).withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                      width: AppTheme.borderHairline,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                            alpha: widget.isDark ? 0.4 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: widget.color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: widget.isDark
                                ? Colors.white
                                : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
