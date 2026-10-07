import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Document 7 (#98) / 12.7: shared empty-state widget for any list screen
/// with zero results — distinct from ErrorStateView (that's a failure; this
/// is "the request succeeded, there's just nothing here").
///
/// An empty screen is an invitation to act: pass [actionLabel] + [onAction]
/// (e.g. "Add buyer") whenever the user can create the first record.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.color,
  });

  final String message;
  final IconData icon;

  /// Optional bold line above [message], e.g. "No buyers yet".
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  /// Tint for the illustration — pass the module colour (default primary).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final accent = color ?? s.primary;
    final isDark = s.brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 128,
                height: 128,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
                      ),
                    ),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                      ),
                      child: Icon(icon, size: 44, color: accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (title != null) ...[
                Text(title!, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: (title == null ? theme.textTheme.bodyLarge : theme.textTheme.bodyMedium)
                    ?.copyWith(color: s.onSurfaceVariant),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon ?? Icons.add_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
