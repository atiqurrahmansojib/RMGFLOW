import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Hero header for dashboards and detail pages: rounded gradient panel with
/// a faint oversized icon watermark, title, subtitle, optional status chip /
/// leading avatar and a bottom slot (e.g. a row of mini stats or actions).
///
/// Place as the first child of a scroll view (not in the AppBar). For a
/// module page pass `colors: [module.color, …]` or use [GradientHeader.module].
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.icon,
    this.leading,
    this.trailing,
    this.bottom,
    this.gradient,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
    this.padding = const EdgeInsets.all(20),
  });

  GradientHeader.module(
    AppModule module, {
    Key? key,
    required String title,
    String? subtitle,
    String? eyebrow,
    Widget? leading,
    Widget? trailing,
    Widget? bottom,
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  }) : this(
          key: key,
          title: title,
          subtitle: subtitle,
          eyebrow: eyebrow,
          icon: module.icon,
          leading: leading,
          trailing: trailing,
          bottom: bottom,
          gradient: module.gradient,
          margin: margin,
        );

  final String title;
  final String? subtitle;

  /// Small line above the title, e.g. the record number "PO-2026-0142".
  final String? eyebrow;

  /// Watermark icon drawn large and faint at the right edge.
  final IconData? icon;
  final Widget? leading;

  /// Top-right slot — typically a [StatusChip] or an IconButton.
  final Widget? trailing;
  final Widget? bottom;

  /// Default: [AppColors.brandGradient].
  final Gradient? gradient;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = gradient ?? AppColors.brandGradient;
    final shadowColor = g.colors.first;
    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          gradient: g,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: theme.brightness == Brightness.dark
              ? null
              : [BoxShadow(color: shadowColor.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (icon != null)
              Positioned(
                right: -18,
                bottom: -22,
                child: Icon(icon, size: 140, color: Colors.white.withValues(alpha: 0.10)),
              ),
            Padding(
              padding: padding,
              child: IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                if (eyebrow != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(eyebrow!,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                                  ),
                                Text(title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                                if (subtitle != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(subtitle!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                                  ),
                              ],
                            ),
                          ),
                          if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
                        ],
                      ),
                      if (bottom != null) ...[const SizedBox(height: AppSpacing.lg), bottom!],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact white-on-gradient figure for [GradientHeader.bottom], e.g.
/// `Row(children: [HeaderStat(value: '12,400', label: 'Order qty'), ...])`.
class HeaderStat extends StatelessWidget {
  const HeaderStat({super.key, required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: t.titleLarge?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()])),
        Text(label,
            style: t.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
      ],
    );
  }
}
