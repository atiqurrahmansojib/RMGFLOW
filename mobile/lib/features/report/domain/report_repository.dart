import 'report.dart';

/// Document 12.2: domain contract for /api/v1/reports. Filters are passed as
/// already-serialized query values (dates yyyy-MM-dd, buyer/factory ids).
abstract class ReportRepository {
  Future<List<ReportDefinition>> list();
  Future<ReportResult> run(String code, Map<String, String> filters);
  Future<ReportExport> export(String code, ReportExportFormat format, Map<String, String> filters);
}
