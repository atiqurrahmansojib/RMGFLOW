import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Pill badge for any workflow status. Pass the raw status string (API value
/// `IN_PROGRESS`, enum `.name` like `inProgress`, or plain text) — colour,
/// icon and a readable label ("In progress") are resolved by [AppStatus].
class StatusChip extends StatelessWidget {
  const StatusChip(
    this.status, {
    super.key,
    this.label,
    this.tone,
    this.showIcon = true,
    this.dense = false,
  });

  /// Raw status string, e.g. `'APPROVED'`, `'inProgress'`, `'on track'`.
  final String status;

  /// Override the displayed label (default: humanised [status]).
  final String? label;

  /// Override the resolved tone (e.g. to force danger for a domain rule).
  final StatusTone? tone;
  final bool showIcon;

  /// Smaller variant for use inside dense list rows / tables.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = AppStatus.resolve(status);
    final t = tone ?? style.tone;
    final brightness = Theme.of(context).brightness;
    final fg = t.foreground(brightness);
    final textStyle = (dense ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.labelMedium)
        ?.copyWith(color: fg, fontWeight: FontWeight.w700);

    return Semantics(
      label: 'Status: ${label ?? style.label}',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
        decoration: BoxDecoration(
          color: t.background(brightness),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(style.icon, size: dense ? 12 : 14, color: fg),
              SizedBox(width: dense ? 4 : 5),
            ],
            Text(label ?? style.label, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
