import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/widgets.dart';
import '../application/report_controller.dart';
import '../domain/report.dart';
import 'report_screen.dart';
import 'widgets/report_category_style.dart';

/// Document 14: reports hub — every report the user may run, grouped by
/// category, with a search box over name/description/category.
class ReportHubScreen extends ConsumerStatefulWidget {
  const ReportHubScreen({super.key});

  @override
  ConsumerState<ReportHubScreen> createState() => _ReportHubScreenState();
}

class _ReportHubScreenState extends ConsumerState<ReportHubScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportCatalogControllerProvider);
    final controller = ref.read(reportCatalogControllerProvider.notifier);

    final count = state is ReportCatalogLoaded ? state.reports.length : null;
    final categories = state is ReportCatalogLoaded ? state.reports.map((r) => r.category).toSet().length : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          GradientHeader.module(
            AppModules.reports,
            title: 'Reports & Analytics',
            subtitle: 'Run business reports and download them as CSV or PDF',
            bottom: count == null
                ? null
                : Row(
                    children: [
                      HeaderStat(value: '$count', label: count == 1 ? 'Report' : 'Reports'),
                      const SizedBox(width: AppSpacing.xxl),
                      HeaderStat(value: '$categories', label: categories == 1 ? 'Category' : 'Categories'),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
            child: SearchField(
              controller: _searchController,
              hintText: 'Search reports',
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: switch (state) {
              ReportCatalogLoading() => const LoadingView(),
              ReportCatalogError(:final failure) => ErrorStateView(failure: failure, onRetry: controller.load),
              ReportCatalogLoaded(:final reports) => RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: _buildList(context, reports),
                ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ReportDefinition> reports) {
    final filtered = _query.isEmpty
        ? reports
        : reports
            .where((r) =>
                r.name.toLowerCase().contains(_query) ||
                r.category.toLowerCase().contains(_query) ||
                (r.description?.toLowerCase().contains(_query) ?? false))
            .toList();

    if (filtered.isEmpty) {
      // Still scrollable so pull-to-refresh works on an empty result.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyStateView(
            color: AppModules.reports.color,
            message: reports.isEmpty
                ? 'No reports are available for your role.'
                : 'No reports match "${_searchController.text.trim()}".',
            icon: Icons.bar_chart_outlined,
          ),
        ],
      );
    }

    // Preserve the server's category order (first appearance wins).
    final groups = <String, List<ReportDefinition>>{};
    for (final report in filtered) {
      groups.putIfAbsent(report.category, () => []).add(report);
    }

    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: [
        for (final entry in groups.entries) ...[
          SectionHeader(
            entry.key,
            icon: _categoryIcon(entry.key),
            count: entry.value.length,
            accentColor: reportCategoryModule(entry.key).color,
          ),
          for (final report in entry.value)
            Builder(builder: (context) {
              final module = reportCategoryModule(report.category);
              return AppCard(
                accentColor: module.color,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ReportScreen(definition: report)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: module.gradient,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(_categoryIcon(report.category), color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          if (report.description != null && report.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xxs),
                              child: Text(
                                report.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.chevron_right_rounded, color: module.color),
                  ],
                ),
              );
            }),
        ],
      ],
    );
  }

  static IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('buyer')) return Icons.business_outlined;
    if (c.contains('inquir') || c.contains('sales')) return Icons.mail_outline;
    if (c.contains('cost') || c.contains('margin')) return Icons.calculate_outlined;
    if (c.contains('order')) return Icons.receipt_long_outlined;
    if (c.contains('t&a') || c.contains('delay')) return Icons.timeline_outlined;
    if (c.contains('production')) return Icons.precision_manufacturing_outlined;
    if (c.contains('quality')) return Icons.verified_outlined;
    if (c.contains('sample')) return Icons.science_outlined;
    if (c.contains('ship') || c.contains('logistic')) return Icons.local_shipping_outlined;
    if (c.contains('document') || c.contains('commercial')) return Icons.description_outlined;
    if (c.contains('financ') || c.contains('account')) return Icons.account_balance_wallet_outlined;
    if (c.contains('claim')) return Icons.report_problem_outlined;
    return Icons.bar_chart_outlined;
  }
}
