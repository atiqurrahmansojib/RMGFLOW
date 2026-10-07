import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Title row that introduces a group of content, with optional count badge,
/// subtitle and trailing action (e.g. "See all").
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.count,
    this.icon,
    this.accentColor,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(4, AppSpacing.lg, 4, AppSpacing.sm),
  });

  final String title;
  final String? subtitle;
  final int? count;
  final IconData? icon;
  final Color? accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Custom trailing widget; takes precedence over [actionLabel].
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final accent = accentColor ?? s.primary;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('$count',
                            style: theme.textTheme.labelSmall?.copyWith(color: accent, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                foregroundColor: accent,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
