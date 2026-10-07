import 'package:intl/intl.dart';

import '../../domain/report.dart';

/// Display-only formatting for generic report cells. Values are never
/// recomputed client-side (NFR-01) — only rendered.
///
/// `percent` values arrive already in percent units (12.5 means 12.5%), the
/// same convention as Costing.marginPercent.
final _number = NumberFormat('#,##0.##');
final _money = NumberFormat('#,##0.00');
final _date = DateFormat('dd MMM yyyy');

const reportEmptyValue = '—';

String formatReportValue(Object? value, ReportColumnType type) {
  if (value == null) return reportEmptyValue;
  if (value is String && value.trim().isEmpty) return reportEmptyValue;

  switch (type) {
    case ReportColumnType.number:
      final n = _asNum(value);
      return n == null ? value.toString() : _number.format(n);
    case ReportColumnType.money:
      final n = _asNum(value);
      return n == null ? value.toString() : _money.format(n);
    case ReportColumnType.percent:
      final n = _asNum(value);
      return n == null ? value.toString() : '${_number.format(n)}%';
    case ReportColumnType.date:
      final d = DateTime.tryParse(value.toString());
      return d == null ? value.toString() : _date.format(d);
    case ReportColumnType.text:
      if (value is bool) return value ? 'Yes' : 'No';
      return value.toString();
  }
}

/// Summary values are untyped on the wire: numbers get grouping separators,
/// everything else is shown as-is.
String formatSummaryValue(Object? value) {
  if (value == null) return reportEmptyValue;
  final n = _asNum(value);
  return n == null ? value.toString() : _number.format(n);
}

num? _asNum(Object value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
