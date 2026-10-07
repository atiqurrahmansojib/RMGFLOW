// Generic report rendering: summary cards + formatted, horizontally
// scrollable table driven entirely by the server's column metadata.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rmgflow_mobile/features/report/data/report_repository_impl.dart';
import 'package:rmgflow_mobile/features/report/domain/report.dart';
import 'package:rmgflow_mobile/features/report/presentation/widgets/report_data_view.dart';
import 'package:rmgflow_mobile/features/report/presentation/widgets/report_value_formatter.dart';

ReportResult _result({List<Map<String, dynamic>>? rows}) => ReportResult.fromJson({
      'code': 'order-status',
      'name': 'Order Status',
      'generatedAt': '2026-10-06T08:30:00Z',
      'columns': [
        {'key': 'orderNo', 'label': 'Order No', 'type': 'text'},
        {'key': 'qty', 'label': 'Quantity', 'type': 'number'},
        {'key': 'value', 'label': 'Order Value', 'type': 'money'},
        {'key': 'shipDate', 'label': 'Ship Date', 'type': 'date'},
        {'key': 'margin', 'label': 'Margin', 'type': 'percent'},
        {'key': 'note', 'label': 'Note', 'type': 'text'},
      ],
      'rows': rows ??
          [
            {'orderNo': 'PO-1001', 'qty': 12500, 'value': 54321.5, 'shipDate': '2026-11-15', 'margin': 12.5, 'note': null},
            {'orderNo': 'PO-1002', 'qty': 800, 'value': '1200', 'shipDate': '2026-12-01', 'margin': 8, 'note': 'Rush'},
          ],
      'summary': [
        {'label': 'Total orders', 'value': 2},
        {'label': 'Total value', 'value': 55521.5},
      ],
    });

Future<void> _pump(WidgetTester tester, ReportResult result) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ListView(children: [ReportDataView(result: result)]),
    ),
  ));
}

void main() {
  testWidgets('renders summary cards, headers and formatted cells', (tester) async {
    await _pump(tester, _result());

    // Summary cards.
    expect(find.text('Total orders'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('55,521.5'), findsOneWidget);

    // Column headers from metadata.
    for (final header in ['Order No', 'Quantity', 'Order Value', 'Ship Date', 'Margin', 'Note']) {
      expect(find.text(header), findsOneWidget);
    }

    // Typed formatting.
    expect(find.text('PO-1001'), findsOneWidget);
    expect(find.text('12,500'), findsOneWidget);
    expect(find.text('54,321.50'), findsOneWidget);
    expect(find.text('1,200.00'), findsOneWidget); // numeric string money
    expect(find.text('15 Nov 2026'), findsOneWidget);
    expect(find.text('12.5%'), findsOneWidget);
    expect(find.text('8%'), findsOneWidget);
    expect(find.text(reportEmptyValue), findsOneWidget); // null cell
    expect(find.textContaining('2 rows'), findsOneWidget);

    // Numeric columns are right-aligned; the table scrolls sideways.
    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.columns.map((c) => c.numeric).toList(), [false, true, true, false, true, false]);
    expect(
      find.ancestor(of: find.byType(DataTable), matching: find.byType(SingleChildScrollView)),
      findsOneWidget,
    );
    final scroll = tester.widget<SingleChildScrollView>(
      find.ancestor(of: find.byType(DataTable), matching: find.byType(SingleChildScrollView)),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
  });

  testWidgets('shows empty state instead of a table when there are no rows', (tester) async {
    await _pump(tester, _result(rows: const []));

    expect(find.byType(DataTable), findsNothing);
    expect(find.textContaining('No data for the selected filters'), findsOneWidget);
    // Summary is still shown.
    expect(find.text('Total orders'), findsOneWidget);
  });

  test('parses filename from Content-Disposition safely', () {
    expect(fileNameFromContentDisposition('attachment; filename="order-status-20261006.pdf"'),
        'order-status-20261006.pdf');
    expect(fileNameFromContentDisposition('attachment; filename="../../etc/passwd"'), 'passwd');
    expect(fileNameFromContentDisposition(null), isNull);
    expect(fileNameFromContentDisposition('attachment'), isNull);
  });

  test('parses report catalog definitions', () {
    final def = ReportDefinition.fromJson({
      'code': 'order-status',
      'name': 'Order Status',
      'category': 'Orders',
      'filters': [
        {'key': 'from', 'label': 'From date', 'type': 'date'},
        {'key': 'status', 'label': 'Status', 'type': 'status', 'required': true, 'options': ['OPEN', 'SHIPPED']},
      ],
    });
    expect(def.filters.first.type, ReportFilterType.date);
    expect(def.filters.last.required, isTrue);
    expect(def.filters.last.options, ['OPEN', 'SHIPPED']);
  });
}
