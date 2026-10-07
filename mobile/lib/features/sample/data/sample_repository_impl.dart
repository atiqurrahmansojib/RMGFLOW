import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/sample.dart';
import '../domain/sample_repository.dart';

/// Document 11.2: talks to /api/v1/samples (+ nested /revisions) — requires
/// SAMPLE_VIEW/SAMPLE_MANAGE/SAMPLE_APPROVE (Doc 5.2).
class SampleRepositoryImpl implements SampleRepository {
  SampleRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Sample>> list({SampleStatus? status, int page = 0, int size = 100}) async {
    final response = await _dio.get('/samples', queryParameters: {
      if (status != null) 'status': status.apiValue,
      'page': page,
      'size': size,
      // Newest first, so client-side search/filter covers recent work.
      'sort': 'id,desc',
    });
    final content = (response.data as Map<String, dynamic>)['content'] as List;
    return content.map((e) => Sample.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Sample> get(int id) async {
    final response = await _dio.get('/samples/$id');
    return Sample.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Sample> create(SampleDraft draft) async {
    final response = await _dio.post('/samples', data: draft.toJson());
    return Sample.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<SampleRevision>> listRevisions(int sampleId) async {
    final response = await _dio.get('/samples/$sampleId/revisions');
    return (response.data as List).map((e) => SampleRevision.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SampleRevision> createRevision(int sampleId, SampleRevisionDraft draft) async {
    final response = await _dio.post('/samples/$sampleId/revisions', data: draft.toJson());
    return SampleRevision.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SampleRevision> syncStatusFromLatestApproval(int sampleId) async {
    final response = await _dio.post('/samples/$sampleId/revisions/sync-status');
    return SampleRevision.fromJson(response.data as Map<String, dynamic>);
  }
}

final sampleRepositoryProvider = Provider<SampleRepository>((ref) {
  return SampleRepositoryImpl(ref.watch(apiDioProvider));
});
