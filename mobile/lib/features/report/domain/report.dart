// Document 14: the reports API is generic — the backend describes each
// report (filters, columns) and the client renders whatever it is told,
// so a new report never needs a mobile release.

enum ReportFilterType {
  date,
  buyer,
  factory,
  status,
  text;

  static ReportFilterType fromApiValue(String? value) => switch (value) {
        'date' => ReportFilterType.date,
        'buyer' => ReportFilterType.buyer,
        'factory' => ReportFilterType.factory,
        'status' => ReportFilterType.status,
        _ => ReportFilterType.text,
      };
}

enum ReportColumnType {
  text,
  number,
  money,
  date,
  percent;

  bool get isNumeric =>
      this == ReportColumnType.number || this == ReportColumnType.money || this == ReportColumnType.percent;

  static ReportColumnType fromApiValue(String? value) => switch (value) {
        'number' => ReportColumnType.number,
        'money' => ReportColumnType.money,
        'date' => ReportColumnType.date,
        'percent' => ReportColumnType.percent,
        _ => ReportColumnType.text,
      };
}

/// Export formats accepted by GET /reports/{code}/export?format=...
enum ReportExportFormat {
  csv,
  pdf;

  String get apiValue => name;
  String get extension => name;
  String get label => name.toUpperCase();
  String get mimeType => this == ReportExportFormat.csv ? 'text/csv' : 'application/pdf';
}

class ReportFilterDefinition {
  const ReportFilterDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.options = const [],
  });

  factory ReportFilterDefinition.fromJson(Map<String, dynamic> json) => ReportFilterDefinition(
        key: json['key'] as String,
        label: (json['label'] as String?) ?? json['key'] as String,
        type: ReportFilterType.fromApiValue(json['type'] as String?),
        required: (json['required'] as bool?) ?? false,
        options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );

  final String key;
  final String label;
  final ReportFilterType type;
  final bool required;

  /// Only populated for [ReportFilterType.status].
  final List<String> options;
}

class ReportDefinition {
  const ReportDefinition({
    required this.code,
    required this.name,
    required this.category,
    this.description,
    this.filters = const [],
  });

  factory ReportDefinition.fromJson(Map<String, dynamic> json) => ReportDefinition(
        code: json['code'] as String,
        name: json['name'] as String,
        category: (json['category'] as String?) ?? 'Other',
        description: json['description'] as String?,
        filters: (json['filters'] as List? ?? const [])
            .map((e) => ReportFilterDefinition.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String code;
  final String name;
  final String category;
  final String? description;
  final List<ReportFilterDefinition> filters;
}

class ReportColumn {
  const ReportColumn({required this.key, required this.label, required this.type});

  factory ReportColumn.fromJson(Map<String, dynamic> json) => ReportColumn(
        key: json['key'] as String,
        label: (json['label'] as String?) ?? json['key'] as String,
        type: ReportColumnType.fromApiValue(json['type'] as String?),
      );

  final String key;
  final String label;
  final ReportColumnType type;
}

class ReportSummaryItem {
  const ReportSummaryItem({required this.label, required this.value});

  factory ReportSummaryItem.fromJson(Map<String, dynamic> json) =>
      ReportSummaryItem(label: json['label'] as String, value: json['value']);

  final String label;

  /// Untyped on the wire (count, amount or text) — formatted for display only.
  final Object? value;
}

class ReportResult {
  const ReportResult({
    required this.code,
    required this.name,
    this.generatedAt,
    required this.columns,
    required this.rows,
    this.summary = const [],
  });

  factory ReportResult.fromJson(Map<String, dynamic> json) => ReportResult(
        code: json['code'] as String,
        name: json['name'] as String,
        generatedAt: DateTime.tryParse((json['generatedAt'] as String?) ?? ''),
        columns: (json['columns'] as List? ?? const [])
            .map((e) => ReportColumn.fromJson(e as Map<String, dynamic>))
            .toList(),
        rows: (json['rows'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        summary: (json['summary'] as List? ?? const [])
            .map((e) => ReportSummaryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String code;
  final String name;
  final DateTime? generatedAt;
  final List<ReportColumn> columns;
  final List<Map<String, dynamic>> rows;
  final List<ReportSummaryItem> summary;
}

/// Downloaded export bytes plus the server-suggested file name.
class ReportExport {
  const ReportExport({required this.fileName, required this.bytes, required this.format});

  final String fileName;
  final List<int> bytes;
  final ReportExportFormat format;
}
