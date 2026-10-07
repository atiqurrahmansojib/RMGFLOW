import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'date_field.dart';
import 'status_chip.dart';

/// Shared row/quick-action helpers for the follow-up modules (orders, T&A,
/// production, quality, shipment, documents, financials, claims, tasks,
/// activity, notifications, My Day). Import alongside `widgets.dart`.

final NumberFormat _money = NumberFormat('#,##0.00');
final NumberFormat _qty = NumberFormat('#,##0');

/// `USD 12,400.00`.
String fmtMoney(String currency, num value) => '$currency ${_money.format(value)}';

/// `12,400`.
String fmtQty(num value) => _qty.format(value);

/// `12.4K`.
String fmtCompact(num value) => NumberFormat.compact().format(value);

/// Whole days from today to [apiDate] (negative = in the past); null if unset.
int? daysFromToday(String? apiDate) {
  final d = parseApiDate(apiDate);
  if (d == null) return null;
  return DateUtils.dateOnly(d).difference(DateUtils.dateOnly(DateTime.now())).inDays;
}

/// "in 5 d" / "today" / "3 d late" for a due date.
String relativeDays(int days) => days == 0
    ? 'today'
    : days > 0
        ? 'in $days d'
        : '${-days} d late';

/// Gradient icon square used as the leading element of rows and tiles.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 44});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient(color),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      );
}

/// Standard list-row body: optional leading badge, bold title, muted
/// subtitle lines and a trailing widget (usually a dense [StatusChip]).
class RecordRow extends StatelessWidget {
  const RecordRow({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.leading,
    this.trailing,
    this.footer,
  });

  final String title;
  final String? subtitle;

  /// Third, smaller line (dates, amounts).
  final String? meta;
  final Widget? leading;
  final Widget? trailing;

  /// Extra content under the text (buttons, progress…).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Text(subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                    ),
                  if (meta != null && meta!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Text(meta!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(color: s.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
          ],
        ),
        if (footer != null) ...[const SizedBox(height: AppSpacing.md), footer!],
      ],
    );
  }
}

/// One entry of a long-press / row quick-action sheet.
class QuickAction {
  const QuickAction({required this.icon, required this.label, required this.onTap, this.color, this.subtitle});
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;
}

/// Bottom sheet listing [actions]; the sheet closes before the action runs.
Future<void> showQuickActions(BuildContext context,
    {required String title, String? subtitle, required List<QuickAction> actions}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            for (final a in actions)
              ListTile(
                leading: IconBadge(icon: a.icon, color: a.color ?? theme.colorScheme.primary, size: 36),
                title: Text(a.label),
                subtitle: a.subtitle == null ? null : Text(a.subtitle!),
                onTap: () {
                  Navigator.of(ctx).pop();
                  a.onTap();
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}

/// Swipe-to-act wrapper (no extra package). The row snaps back after the
/// action runs — the list is expected to refresh with the new state.
class SwipeAction extends StatelessWidget {
  const SwipeAction({
    super.key,
    required this.child,
    this.startLabel,
    this.startIcon,
    this.startColor,
    this.onSwipeStart,
    this.endLabel,
    this.endIcon,
    this.endColor,
    this.onSwipeEnd,
  });

  final Widget child;

  /// Swipe left-to-right.
  final String? startLabel;
  final IconData? startIcon;
  final Color? startColor;
  final Future<void> Function()? onSwipeStart;

  /// Swipe right-to-left.
  final String? endLabel;
  final IconData? endIcon;
  final Color? endColor;
  final Future<void> Function()? onSwipeEnd;

  Widget _bg(BuildContext context, String? label, IconData? icon, Color? color, Alignment align) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      alignment: align,
      decoration: BoxDecoration(gradient: AppColors.accentGradient(c), borderRadius: AppRadius.card),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: Colors.white),
          if (label != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasStart = onSwipeStart != null;
    final hasEnd = onSwipeEnd != null;
    if (!hasStart && !hasEnd) return child;
    final direction = hasStart && hasEnd
        ? DismissDirection.horizontal
        : hasStart
            ? DismissDirection.startToEnd
            : DismissDirection.endToStart;
    return Dismissible(
      key: key ?? UniqueKey(),
      direction: direction,
      background: hasStart
          ? _bg(context, startLabel, startIcon, startColor, Alignment.centerLeft)
          : _bg(context, endLabel, endIcon, endColor, Alignment.centerRight),
      secondaryBackground: hasStart && hasEnd ? _bg(context, endLabel, endIcon, endColor, Alignment.centerRight) : null,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await onSwipeStart?.call();
        } else {
          await (hasEnd ? onSwipeEnd : onSwipeStart)?.call();
        }
        return false;
      },
      child: child,
    );
  }
}

/// Snackbar with an Undo action. [onCommit] runs when it closes without
/// Undo (timeout, swipe or replaced); [onUndo] when Undo is tapped.
void showUndoSnack(
  BuildContext context,
  String message, {
  required VoidCallback onCommit,
  VoidCallback? onUndo,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger
      .showSnackBar(SnackBar(
        content: Text(message),
        duration: duration,
        persist: false,
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ))
      .closed
      .then((reason) {
    if (reason == SnackBarClosedReason.action) {
      onUndo?.call();
    } else {
      onCommit();
    }
  });
}

/// Labelled progress bar "Sewing · 4,200 / 6,000 pcs · 70%".
class StageProgress extends StatelessWidget {
  const StageProgress({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.icon,
    this.unit = 'pcs',
  });

  final String label;
  final int value;
  final int target;
  final Color color;
  final IconData? icon;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final ratio = target <= 0 ? 0.0 : value / target;
    final pct = (ratio * 100).clamp(0, 999).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: color), const SizedBox(width: AppSpacing.sm)],
              Expanded(child: Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
              Text('${fmtQty(value)} / ${fmtQty(target)} $unit',
                  style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('$pct%',
                    style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

/// [StatusChip] that opens a small menu of next statuses — inline status
/// change from a list row or header. Shows a plain chip when [options] is empty.
class StatusMenuChip<T> extends StatelessWidget {
  const StatusMenuChip({
    super.key,
    required this.status,
    required this.options,
    required this.apiOf,
    required this.labelOf,
    required this.onSelected,
    this.label,
    this.dense = true,
    this.enabled = true,
  });

  final String status;
  final String? label;
  final List<T> options;
  final String Function(T) apiOf;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final bool dense;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chip = StatusChip(status, label: label, dense: dense);
    if (options.isEmpty || !enabled) return chip;
    return PopupMenuButton<T>(
      tooltip: 'Change status',
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem<T>(
            value: o,
            child: Row(children: [
              Icon(AppStatus.resolve(apiOf(o)).icon, color: AppStatus.color(apiOf(o)), size: 20),
              const SizedBox(width: AppSpacing.md),
              Text(labelOf(o)),
            ]),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip,
          Icon(Icons.arrow_drop_down_rounded, color: AppStatus.color(status)),
        ],
      ),
    );
  }
}

/// Small coloured pill for a number/flag, e.g. "3 d late".
class TonePill extends StatelessWidget {
  const TonePill(this.text, {super.key, required this.color, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration:
          BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: AppSpacing.xs)],
          Text(text, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
