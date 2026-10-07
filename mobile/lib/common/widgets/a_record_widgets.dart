import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../lookups/lookup_providers.dart';
import 'app_card.dart';
import 'section_header.dart';
import 'status_chip.dart';

/// Shared building blocks for the "fewest taps" list / form screens:
/// a consistent list row ([RecordTile]), a quick-action bottom sheet
/// ([showQuickActions]), swipe actions ([SwipeActions]), an inline status
/// menu ([StatusMenuChip]) and grouped form sections ([FormSection]).

/// Rounded, tinted square with an icon or initials — the leading of a row.
class RecordAvatar extends StatelessWidget {
  const RecordAvatar({super.key, required this.color, this.icon, this.text, this.size = 44});

  final Color color;
  final IconData? icon;
  final String? text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Color.lerp(color, Colors.white, 0.4)! : color;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.24 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: text != null && text!.isNotEmpty
          ? Text(
              text!,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w800),
            )
          : Icon(icon ?? Icons.circle_outlined, color: fg, size: size * 0.5),
    );
  }
}

/// Initials for an avatar: "H&M Hennes" → "HH", "zara" → "ZA".
String recordInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final w = words.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}

/// One list row: [AppCard] with an accent stripe, leading avatar, bold title,
/// muted subtitle lines and a trailing widget (usually a dense [StatusChip]).
/// [highlighted] tints the card — used to point at a just-created record.
class RecordTile extends StatelessWidget {
  const RecordTile({
    super.key,
    required this.title,
    required this.accentColor,
    this.subtitle,
    this.meta,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.highlighted = false,
  });

  final String title;
  final Color accentColor;
  final String? subtitle;

  /// Optional third line (dates, amounts) shown smaller.
  final String? meta;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return AppCard(
      accentColor: accentColor,
      color: highlighted ? Color.alphaBlend(accentColor.withValues(alpha: 0.10), s.surface) : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (highlighted) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.fiber_new_rounded, size: 18, color: accentColor),
                    ],
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                  ),
                ],
                if (meta != null && meta!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    meta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: s.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
        ],
      ),
    );
  }
}

/// One entry of a quick-action sheet.
class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.color,
    this.subtitle,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final Color? color;
  final String? subtitle;
  final bool destructive;
}

/// Long-press menu: a bottom sheet of the row's most common actions.
Future<void> showQuickActions(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<QuickAction> actions,
}) async {
  final picked = await showModalBottomSheet<QuickAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final s = theme.colorScheme;
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
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                ],
              ),
            ),
            for (final a in actions)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                leading: RecordAvatar(
                  color: a.destructive ? AppColors.danger : (a.color ?? s.primary),
                  icon: a.icon,
                  size: 36,
                ),
                title: Text(
                  a.label,
                  style: a.destructive ? TextStyle(color: s.error, fontWeight: FontWeight.w600) : null,
                ),
                subtitle: a.subtitle == null ? null : Text(a.subtitle!),
                onTap: () => Navigator.of(ctx).pop(a),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
  picked?.onSelected();
}

/// One side of a [SwipeActions] row.
class SwipeAction {
  const SwipeAction({required this.label, required this.icon, required this.color, required this.onTrigger});

  final String label;
  final IconData icon;
  final Color color;

  /// Runs the action. The row is never removed by the swipe itself — the
  /// list refreshes from the server afterwards.
  final Future<void> Function() onTrigger;
}

/// Swipe right for [start], swipe left for [end] (either may be null).
class SwipeActions extends StatelessWidget {
  const SwipeActions({super.key, required this.id, required this.child, this.start, this.end});

  final Object id;
  final Widget child;
  final SwipeAction? start;
  final SwipeAction? end;

  Widget _background(BuildContext context, SwipeAction a, Alignment alignment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(color: a.color, borderRadius: AppRadius.card),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(a.icon, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Text(a.label,
                style:
                    Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (start == null && end == null) return child;
    final direction = start != null && end != null
        ? DismissDirection.horizontal
        : (start != null ? DismissDirection.startToEnd : DismissDirection.endToStart);
    return Dismissible(
      key: ValueKey(('swipe', id)),
      direction: direction,
      dismissThresholds: const {DismissDirection.startToEnd: 0.35, DismissDirection.endToStart: 0.35},
      background: start == null ? const SizedBox.shrink() : _background(context, start!, Alignment.centerLeft),
      secondaryBackground: end == null ? null : _background(context, end!, Alignment.centerRight),
      confirmDismiss: (dir) async {
        final action = dir == DismissDirection.startToEnd ? start : end;
        if (action != null) await action.onTrigger();
        return false;
      },
      child: child,
    );
  }
}

/// A [StatusChip] that opens a small menu of next statuses when tapped —
/// inline status change without opening the record.
class StatusMenuChip<T> extends StatelessWidget {
  const StatusMenuChip({
    super.key,
    required this.status,
    required this.options,
    required this.apiValueOf,
    required this.labelOf,
    required this.onSelected,
    this.label,
    this.dense = true,
    this.enabled = true,
  });

  final String status;
  final String? label;
  final List<T> options;
  final String Function(T) apiValueOf;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final bool dense;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusChip(status, label: label, dense: dense),
        if (enabled && options.isNotEmpty)
          Icon(Icons.arrow_drop_down_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
    if (!enabled || options.isEmpty) return chip;
    return PopupMenuButton<T>(
      tooltip: 'Change status',
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem<T>(
            value: o,
            child: Row(
              children: [
                Icon(AppStatus.resolve(apiValueOf(o)).icon, size: 18, color: AppStatus.color(apiValueOf(o))),
                const SizedBox(width: AppSpacing.md),
                Text(labelOf(o)),
              ],
            ),
          ),
      ],
      child: chip,
    );
  }
}

/// A titled group of form fields inside an [AppCard], with even spacing.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.children, this.icon, this.subtitle, this.color});

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title, subtitle: subtitle, icon: icon, accentColor: color),
        AppCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, c) in children.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                c,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A tappable link row inside an [AppCard] (Contacts, Factory candidates…).
class LinkCard extends StatelessWidget {
  const LinkCard({super.key, required this.icon, required this.title, required this.color, this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          RecordAvatar(color: color, icon: icon, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Money formatting used across pricing screens: "USD 1,234.50".
String formatMoney(String? currency, num? amount, {int decimals = 2}) {
  if (amount == null) return '—';
  final fixed = amount.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  final value = parts.length > 1 ? '$whole.${parts[1]}' : whole;
  return currency == null || currency.isEmpty ? value : '$currency $value';
}

/// The id of the only option a lookup offers (null while loading or when
/// there are 0 / several) — used to auto-select single-option pickers.
int? singleOptionId(WidgetRef ref, ProviderBase<AsyncValue<List<LookupOption>>> options) {
  final list = ref.watch(options).valueOrNull;
  return list != null && list.length == 1 ? list.first.id : null;
}

/// Calls [apply] after this frame when [current] is empty and the lookup has
/// exactly one option — so the form never asks the user to pick the obvious.
void autoSelectSingle(
  WidgetRef ref,
  ProviderBase<AsyncValue<List<LookupOption>>> options, {
  required int? current,
  required ValueChanged<int> apply,
}) {
  if (current != null) return;
  final only = singleOptionId(ref, options);
  if (only == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) => apply(only));
}
