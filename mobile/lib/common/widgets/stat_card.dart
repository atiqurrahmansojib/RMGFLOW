import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Direction of a KPI trend; [TrendDirection.up] is not automatically "good"
/// (e.g. overdue going up is bad) — pass [StatCard.trendIsPositive].
enum TrendDirection { up, down, flat }

/// KPI tile: accent icon chip, big tabular value, label, optional trend
/// line. Set [filled] for a gradient hero variant (one per dashboard row).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.trend,
    this.trendLabel,
    this.trendIsPositive,
    this.caption,
    this.onTap,
    this.filled = false,
  });

  final String value;
  final String label;
  final IconData? icon;

  /// Accent colour (default: colorScheme.primary). Use an [AppModule.color].
  final Color? color;
  final TrendDirection? trend;

  /// e.g. "+12% vs last month".
  final String? trendLabel;

  /// Whether the trend is good news. Defaults to `trend == up`.
  final bool? trendIsPositive;
  final String? caption;
  final VoidCallback? onTap;

  /// Gradient background with white text.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final isDark = s.brightness == Brightness.dark;
    final accent = color ?? s.primary;
    final onColor = filled ? Colors.white : s.onSurface;
    final muted = filled ? Colors.white.withValues(alpha: 0.82) : s.onSurfaceVariant;

    final good = trendIsPositive ?? (trend == TrendDirection.up);
    final trendColor = filled
        ? Colors.white
        : trend == TrendDirection.flat
            ? AppColors.neutral
            : (good ? AppColors.success : AppColors.danger);
    final trendIcon = switch (trend) {
      TrendDirection.up => Icons.trending_up_rounded,
      TrendDirection.down => Icons.trending_down_rounded,
      _ => Icons.trending_flat_rounded,
    };

    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        filled ? Colors.white.withValues(alpha: 0.2) : accent.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  ),
                  child: Icon(icon, size: 20, color: filled ? Colors.white : accent),
                ),
              const Spacer(),
              if (onTap != null) Icon(Icons.arrow_outward_rounded, size: 16, color: muted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: onColor,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: muted, fontWeight: FontWeight.w600)),
          if (trend != null || trendLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (trend != null) Icon(trendIcon, size: 16, color: trendColor),
                if (trend != null && trendLabel != null) const SizedBox(width: 4),
                if (trendLabel != null)
                  Flexible(
                    child: Text(trendLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(color: trendColor)),
                  ),
              ],
            ),
          ],
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, style: theme.textTheme.labelSmall?.copyWith(color: muted, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        boxShadow: isDark
            ? null
            : filled
                ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))]
                : AppColors.softShadow(s.shadow, 0.8),
      ),
      child: Material(
        color: filled ? Colors.transparent : s.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: filled ? BorderSide.none : BorderSide(color: s.outlineVariant.withValues(alpha: isDark ? 1 : 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: filled ? BoxDecoration(gradient: AppColors.accentGradient(accent)) : null,
          child: InkWell(onTap: onTap, child: body),
        ),
      ),
    );
  }
}

/// Alias — dashboards may read better as `KpiCard(...)`.
class KpiCard extends StatCard {
  const KpiCard({
    super.key,
    required super.value,
    required super.label,
    super.icon,
    super.color,
    super.trend,
    super.trendLabel,
    super.trendIsPositive,
    super.caption,
    super.onTap,
    super.filled,
  });
}
