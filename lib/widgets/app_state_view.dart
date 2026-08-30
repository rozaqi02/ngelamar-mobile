import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppViewState { loading, empty, error, offline }

/// A recoverable, section-safe state treatment used instead of blank screens.
class AppStateView extends StatelessWidget {
  final AppViewState state;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final bool compact;

  const AppStateView({
    super.key,
    required this.state,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.compact = false,
  });

  IconData get _resolvedIcon =>
      icon ??
      switch (state) {
        AppViewState.loading => Icons.hourglass_top_rounded,
        AppViewState.empty => Icons.inbox_outlined,
        AppViewState.error => Icons.error_outline_rounded,
        AppViewState.offline => Icons.cloud_off_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      container: true,
      liveRegion: state == AppViewState.error || state == AppViewState.offline,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state == AppViewState.loading)
              SizedBox(
                width: compact ? 28 : 36,
                height: compact ? 28 : 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colors.accent,
                ),
              )
            else
              Icon(
                _resolvedIcon,
                size: compact ? 30 : 42,
                color: state == AppViewState.error
                    ? colors.danger
                    : colors.accent,
              ),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppInlineError extends StatefulWidget {
  final String message;
  final Future<void> Function()? onRetry;
  final String retryLabel;

  const AppInlineError({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Coba lagi',
  });

  @override
  State<AppInlineError> createState() => _AppInlineErrorState();
}

class _AppInlineErrorState extends State<AppInlineError> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying || widget.onRetry == null) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry!();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      liveRegion: true,
      label: 'Terjadi masalah. ${widget.message}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colors.danger),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                widget.message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (widget.onRetry != null)
              TextButton(
                onPressed: _retrying ? null : _retry,
                child: _retrying
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.retryLabel),
              ),
          ],
        ),
      ),
    );
  }
}
