import 'package:flutter/material.dart';

import '../../core/network/failure.dart';
import '../../core/theme/app_tokens.dart';

/// Document 7 (#99) / 12.7: shared error-state widget driven by the Failure
/// type (core/network/failure.dart) — never a raw exception message shown
/// to the user. Picks a fitting icon and headline per Failure subtype.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.failure,
    this.onRetry,
    this.title,
    this.retryLabel = 'Try again',
    this.compact = false,
  });

  final Failure failure;
  final VoidCallback? onRetry;

  /// Override the headline (default derived from the failure type).
  final String? title;
  final String retryLabel;

  /// Smaller layout for use inside a card/section instead of a full screen.
  final bool compact;

  (IconData, String) _visual() => switch (failure) {
        NetworkFailure() => (Icons.wifi_off_rounded, "You're offline"),
        AuthFailure() => (Icons.lock_clock_rounded, 'Session expired'),
        ForbiddenFailure() => (Icons.block_rounded, 'No access'),
        ValidationFailure() => (Icons.rule_rounded, 'Check the details'),
        ConflictFailure() => (Icons.sync_problem_rounded, 'Record changed'),
        ServerFailure() => (Icons.cloud_off_rounded, 'Server problem'),
        UnknownFailure() => (Icons.error_outline_rounded, 'Could not load'),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final (icon, headline) = _visual();
    final f = failure;
    final circle = compact ? 64.0 : 96.0;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: circle,
                height: circle,
                decoration: BoxDecoration(shape: BoxShape.circle, color: s.errorContainer.withValues(alpha: 0.7)),
                child: Icon(icon, size: circle * 0.46, color: s.error),
              ),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
              Text(title ?? headline,
                  textAlign: TextAlign.center,
                  style: compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(f.message,
                  textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
              if (f is ValidationFailure && f.fieldErrors.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: s.errorContainer.withValues(alpha: 0.4),
                    borderRadius: AppRadius.input,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: f.fieldErrors
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.circle, size: 6, color: s.error),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(e, style: theme.textTheme.bodySmall)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
              if (onRetry != null) ...[
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(retryLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
