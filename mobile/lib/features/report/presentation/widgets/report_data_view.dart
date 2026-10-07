import 'package:flutter/material.dart';

import '../../../../common/widgets/widgets.dart';
import '../../domain/report.dart';
import 'report_category_style.dart';
import 'report_value_formatter.dart';

/// Renders any ReportResult generically: summary cards on top, then a
/// horizontally-scrollable table built from the server's column list.
/// Meant to sit inside a vertical scroll view (the report screen's ListView).
class ReportDataView extends StatelessWidget {
  const ReportDataView({super.key, required this.result});

  final ReportResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.summary.isNotEmpty) ...[
          ReportSummaryCards(items: result.summary),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (result.rows.isEmpty || result.columns.isEmpty)
          EmptyStateView(
            color: AppModules.reports.color,
            message: 'No data for the selected filters.\nTry widening the date range or clearing a filter.',
            icon: Icons.table_rows_outlined,
          )
        else
          ReportTable(columns: result.columns, rows: result.rows),
      ],
    );
  }
}

class ReportSummaryCards extends StatelessWidget {
  const ReportSummaryCards({super.key, required this.items});

  final List<ReportSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Two cards per row on phones, more on wider screens.
      final columns = constraints.maxWidth >= 720 ? 4 : (constraints.maxWidth >= 480 ? 3 : 2);
      final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: width,
              child: StatCard(
                value: formatSummaryValue(items[i].value),
                label: items[i].label,
                icon: reportSummaryIcon(items[i].label),
                color: i == 0 ? AppModules.reports.color : reportSummaryPalette[(i - 1) % reportSummaryPalette.length],
                filled: i == 0,
              ),
            ),
        ],
      );
    });
  }
}

class ReportTable extends StatelessWidget {
  const ReportTable({super.key, required this.columns, required this.rows});

  final List<ReportColumn> columns;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final accent = AppModules.reports.color;
    return AppCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.table_rows_rounded, size: 18, color: accent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${rows.length} ${rows.length == 1 ? 'row' : 'rows'} · swipe sideways to see all columns',
                    style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.10)),
              headingTextStyle: theme.textTheme.labelLarge?.copyWith(color: s.onSurface, fontWeight: FontWeight.w700),
              columnSpacing: AppSpacing.xl,
              horizontalMargin: AppSpacing.lg,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 56,
              dividerThickness: 0.6,
              columns: [
                for (final column in columns)
                  DataColumn(
                    label: Text(column.label),
                    numeric: column.type.isNumeric,
                  ),
              ],
              rows: [
                for (var i = 0; i < rows.length; i++)
                  DataRow(
                    color: i.isOdd ? WidgetStatePropertyAll(s.surfaceContainerLow) : null,
                    cells: [
                      for (final column in columns) _cell(rows[i][column.key], column),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataCell _cell(Object? value, ReportColumn column) {
    final text = formatReportValue(value, column.type);
    if (column.type == ReportColumnType.text && text != reportEmptyValue && isStatusColumn(column.key, column.label)) {
      return DataCell(StatusChip(value.toString(), dense: true));
    }
    return DataCell(Text(text));
  }
}
