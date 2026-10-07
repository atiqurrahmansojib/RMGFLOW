import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// The standard content surface: 16px radius, hairline border, soft tinted
/// shadow, optional tap ripple and an optional left accent stripe (use the
/// module or status colour to make rows scannable).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.accentColor,
    this.color,
    this.elevated = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Draws a 4px stripe down the left edge.
  final Color? accentColor;

  /// Background override (default: colorScheme.surface).
  final Color? color;

  /// Soft shadow on/off (off = flat bordered card, good for nested cards).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final isDark = s.brightness == Brightness.dark;
    Widget content = Padding(padding: padding, child: child);
    if (accentColor != null) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(child: content),
          ],
        ),
      );
    }
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          boxShadow: elevated && !isDark ? AppColors.softShadow(s.shadow, 0.8) : null,
        ),
        child: Material(
          color: color ?? s.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.card,
            side: BorderSide(color: s.outlineVariant.withValues(alpha: isDark ? 1 : 0.7)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, onLongPress: onLongPress, child: content),
        ),
      ),
    );
  }
}
