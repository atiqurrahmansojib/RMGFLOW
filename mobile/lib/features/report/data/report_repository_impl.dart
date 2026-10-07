import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../domain/report.dart';
import '../domain/report_repository.dart';

/// Document 11.2/14: talks to /api/v1/reports. RBAC is enforced server-side
/// per report (financial reports need financial permission, Doc 5) — the
/// catalog only lists what the caller may run.
class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<ReportDefinition>> list() async {
    final response = await _dio.get('/reports');
    return (response.data as List).map((e) => ReportDefinition.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ReportResult> run(String code, Map<String, String> filters) async {
    final response = await _dio.get(
      '/reports/$code',
      queryParameters: filters,
      // Large reports can take longer than the default 15s to assemble.
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    return ReportResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ReportExport> export(String code, ReportExportFormat format, Map<String, String> filters) async {
    final response = await _dio.get<List<int>>(
      '/reports/$code/export',
      queryParameters: {...filters, 'format': format.apiValue},
      options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 120)),
    );
    final fileName = fileNameFromContentDisposition(response.headers.value('content-disposition')) ??
        '$code-${DateFormat('yyyyMMdd').format(DateTime.now())}.${format.extension}';
    return ReportExport(fileName: fileName, bytes: response.data ?? const [], format: format);
  }
}

/// Extracts `filename="..."` from a Content-Disposition header, stripping any
/// path components so a hostile name can't escape the target directory.
String? fileNameFromContentDisposition(String? header) {
  if (header == null) return null;
  final match = RegExp(r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''', caseSensitive: false).firstMatch(header);
  final raw = match?.group(1)?.trim();
  if (raw == null || raw.isEmpty) return null;
  String decoded;
  try {
    decoded = Uri.decodeComponent(raw);
  } catch (_) {
    decoded = raw;
  }
  final name = decoded.split(RegExp(r'[/\\]')).last.trim();
  return name.isEmpty ? null : name;
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.watch(apiDioProvider));
});
