import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'apple_animations.dart';

/// Circular "?" control used in screen headers to reopen that menu's tutorial.
class HeaderHelpButton extends StatelessWidget {
  final VoidCallback onTap;
  final String semanticLabel;
  final double size;
  final Color iconColor;

  const HeaderHelpButton({
    super.key,
    required this.onTap,
    this.semanticLabel = 'Buka tutorial menu ini',
    this.size = 38,
    this.iconColor = const Color(0xFF5C44E4),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return FluidBounceButton(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      semanticLabel: semanticLabel,
      hapticEnabled: false,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242428) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? const Color(0xFF383842) : const Color(0xFFE5E0D5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          CupertinoIcons.question_circle_fill,
          size: size * 0.45,
          color: iconColor,
        ),
      ),
    );
  }
}
