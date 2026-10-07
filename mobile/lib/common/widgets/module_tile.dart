import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Home-grid tile: gradient icon square + label (+ optional badge count and
/// caption). Build from the registry with [ModuleTile.fromModule].
class ModuleTile extends StatelessWidget {
  const ModuleTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.badgeCount,
    this.caption,
  });

  ModuleTile.fromModule(
    AppModule module, {
    Key? key,
    VoidCallback? onTap,
    int? badgeCount,
    String? caption,
  }) : this(
          key: key,
          label: module.label,
          icon: module.icon,
          color: module.color,
          onTap: onTap,
          badgeCount: badgeCount,
          caption: caption,
        );

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  /// Pending-items badge (hidden when null or 0).
  final int? badgeCount;

  /// Small secondary line under the label, e.g. "4 overdue".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final isDark = s.brightness == Brightness.dark;
    return Material(
      color: s.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: s.outlineVariant.withValues(alpha: isDark ? 1 : 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient(color),
                      borderRadius: BorderRadius.circular(AppRadius.md + 2),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))
                            ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  if ((badgeCount ?? 0) > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: s.tertiary,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: s.surface, width: 2),
                        ),
                        child: Text(
                          badgeCount! > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(color: s.onTertiary, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: s.onSurface),
              ),
              if (caption != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    caption!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
