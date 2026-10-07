# RMGFlow Mobile Design System ("Indigo & Thread")

Source: `mobile/lib/core/theme/` (`app_theme.dart`, `app_colors.dart`, `app_tokens.dart`) and `mobile/lib/common/widgets/` (import everything via `common/widgets/widgets.dart`).

## Palette
| Role | Light | Dark |
|---|---|---|
| Primary (indigo) | `#3B3FB6` / deep `#262A85` / container `#E3E4FB` | `#A9ADFF` / container `#30349A` |
| Secondary (teal) | `#0E8C7F` / container `#CFF1EC` | `#5FD4C4` |
| Tertiary (coral) | `#E8505B` / container `#FFE0E2` | `#FF8A92` |
| Accent (marigold) | `#F4A62A` / soft `#FFEDCC` | — |
| Scaffold | `#F5F6FB` | `#0F1020` |
| Card | `#FFFFFF` | `#181A2E` |

Status: success `#1E9E5A`, warning `#E08A00`, danger `#D63A3A`, info `#2F7CE0`, neutral `#6E7391`, progress = indigo.

Each module has an accent colour and icon in `AppModules` (`AppModules.byId('orders')`, `AppModules.all`). `AppStatus.resolve(status)` maps any status spelling (`IN_PROGRESS`, `inProgress`, `in progress`) to a colour, readable label and icon. Unknown statuses fall back to neutral.

## Widgets
- `StatusChip(status, {dense})`: a coloured status pill.
- `ModuleTile.fromModule(module, {onTap, badgeCount, caption})`: a home-grid tile.
- `StatCard` / `KpiCard(value, label, {icon, color, trend, trendIsPositive, filled})`.
- `SectionHeader(title, {count, actionLabel, onAction, icon})`.
- `GradientHeader.module(module, {title, subtitle, eyebrow, trailing, bottom})` plus `HeaderStat(value, label)`.
- `InfoRow(label, value, {emphasize, vertical, copyable})`.
- `AppCard(child, {onTap, accentColor})`.
- `PrimaryButton(label, onPressed, {loading, variant: filled|tonal|outlined|danger})`.
- `SearchField({onChanged, debounce})`.
- `LoadingView({layout: list|detail|grid|spinner})`: a shimmer skeleton.
- `EmptyStateView(message, {title, actionLabel, onAction, color})`.
- `ErrorStateView(failure, {onRetry})`.

## Rules for screens
1. **Hard-coded values:** use tokens (`AppSpacing`, `AppRadius`, `AppColors`, `colorScheme`), never hex values, radii or padding numbers.
2. **Status colours:** replace each screen's own `_statusColor` function and coloured `Chip` with `StatusChip`.
3. **Lists:** use an `AppCard` per item, with `accentColor` set to the status or module colour, a `StatusChip` on the right, a `SearchField` on top and pull-to-refresh.
4. **Detail screens:** start with `GradientHeader.module`. Follow it with a `SectionHeader` per group, each above an `AppCard` of `InfoRow`s.
5. **Home:** a 3-column `ModuleTile` grid, a 2-column `StatCard` KPI grid, and `SectionHeader`s.
6. **Forms:** use plain `TextFormField`s, which the theme already styles. Submit with `PrimaryButton`, and use the `danger` variant for destructive actions.
7. **Optional font:** add `google_fonts` (Plus Jakarta Sans for headings, Inter for body text) in `AppTheme._textTheme`.
