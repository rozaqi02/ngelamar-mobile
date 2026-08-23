import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern App Dialog dengan gaya Neo-Modern Bento Card.
/// Menggantikan CupertinoAlertDialog / popup gaya iOS dengan style native aplikasi Ngelamar.
class AppDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    IconData? icon,
    Color? iconColor,
    String primaryLabel = 'Oke',
    VoidCallback? onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    bool isDestructive = false,
    Widget? customBody,
    bool barrierDismissible = true,
  }) {
    HapticFeedback.selectionClick();
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        Widget actionButton({required bool primary}) {
          final label = primary ? primaryLabel : secondaryLabel!;
          final callback = primary
              ? (onPrimary ?? () => Navigator.pop(ctx, true))
              : (onSecondary ?? () => Navigator.pop(ctx, false));
          if (primary) {
            return SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: callback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive
                      ? const Color(0xFFE53935)
                      : const Color(0xFF19191B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }
          return SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: callback,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF44444A)
                      : const Color(0xFFDCD8CE),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                foregroundColor: isDark
                    ? Colors.white70
                    : const Color(0xFF121214),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF333338)
                      : const Color(0xFFE5E0D5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: (iconColor ?? const Color(0xFF5C44E4))
                            .withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: iconColor ?? const Color(0xFF5C44E4),
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF121214),
                    ),
                  ),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      content,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.42,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF555558),
                      ),
                    ),
                  ],
                  if (customBody != null) ...[
                    const SizedBox(height: 14),
                    customBody,
                  ],
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final vertical =
                          constraints.maxWidth < 330 || textScale > 1.3;
                      if (vertical) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (secondaryLabel != null) ...[
                              actionButton(primary: false),
                              const SizedBox(height: 10),
                            ],
                            actionButton(primary: true),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          if (secondaryLabel != null) ...[
                            Expanded(child: actionButton(primary: false)),
                            const SizedBox(width: 10),
                          ],
                          Expanded(child: actionButton(primary: true)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
