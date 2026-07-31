import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppleSheetWindow {
  static Future<T?> showAppleModalSheet<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = true,
  }) {
    final isDark = AppTheme.isDark(context);
    final surf = AppTheme.getSurface(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.7)
          : Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(top: 40),
          decoration: BoxDecoration(
            color: surf,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border.all(
              color: bdr,
              width: AppTheme.borderHairline,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Apple Window Grab Handle Bar
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),

              // Title Header (if provided)
              if (title != null) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: txtPri,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 16,
                            color: txtSec,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: bdr, height: 16),
              ],

              // Content Body
              Flexible(child: child),
            ],
          ),
        );
      },
    );
  }
}
