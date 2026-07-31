import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// Reusable Apple-styled inline badge for job cards & detail screens.
class AppleInlineBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const AppleInlineBadge({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final txtTer = AppTheme.getTextTertiary(context);
    final badgeColor = color ?? txtTer;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.getTextSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
