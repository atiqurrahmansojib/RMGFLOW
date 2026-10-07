import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Label/value pair for detail screens. Empty / null values render as an
/// em dash so layouts never collapse. Set [vertical] for long values
/// (remarks, addresses) to stack label above value.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.icon,
    this.vertical = false,
    this.emphasize = false,
    this.valueColor,
    this.onTap,
    this.copyable = false,
  });

  final String label;
  final String? value;

  /// Custom value (e.g. a [StatusChip]); takes precedence over [value].
  final Widget? valueWidget;
  final IconData? icon;
  final bool vertical;

  /// Bold/larger value — use for money totals and key figures.
  final bool emphasize;
  final Color? valueColor;
  final VoidCallback? onTap;

  /// Allows text selection on the value (PO numbers, LC numbers…).
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final text = (value == null || value!.trim().isEmpty) ? '—' : value!;
    final valueStyle = (emphasize ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)?.copyWith(
      color: valueColor ?? s.onSurface,
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
    );
    final labelStyle = theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w500);
    final valueChild =
        valueWidget ?? (copyable ? SelectableText(text, style: valueStyle) : Text(text, style: valueStyle));

    final labelChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: s.onSurfaceVariant),
          const SizedBox(width: 6),
        ],
        Flexible(child: Text(label, style: labelStyle)),
      ],
    );

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelChild, const SizedBox(height: 4), valueChild],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(top: 2), child: labelChild)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 3,
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: valueWidget ??
                          DefaultTextStyle.merge(
                            textAlign: TextAlign.right,
                            child: valueChild,
                          )),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: s.onSurfaceVariant),
                ],
              ],
            ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, borderRadius: AppRadius.input, child: row);
  }
}
