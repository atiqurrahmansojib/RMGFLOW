import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/costing.dart';
import '../domain/costing_repository.dart';

/// Document 11.2: talks to /api/v1/costings — requires COSTING_VIEW/COSTING_MANAGE
/// (Doc 5.2); all margin math is server-computed, this layer never touches it.
class CostingRepositoryImpl implements CostingRepository {
  CostingRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Costing>> list({int? styleId, int page = 0, int size = 100}) async {
    final response = await _dio.get('/costings', queryParameters: {
      if (styleId != null) 'styleId': styleId,
      'page': page,
      'size': size,
      // Newest first, so client-side search/filter covers recent work.
      'sort': 'id,desc',
    });
    final content = (response.data as Map<String, dynamic>)['content'] as List;
    return content.map((e) => Costing.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Costing> get(int id) async {
    final response = await _dio.get('/costings/$id');
    return Costing.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Costing> create(CostingDraft draft) async {
    final response = await _dio.post('/costings', data: draft.toJson());
    return Costing.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Costing> updateDraft(int id, CostingDraft draft) async {
    final response = await _dio.put('/costings/$id', data: draft.toJson());
    return Costing.fromJson(response.data as Map<String, dynamic>);
  }

  /// Document 9.1: the only way to change an APPROVED costing's numbers.
  @override
  Future<Costing> createRevision(int id, CostingDraft draft) async {
    final response = await _dio.post('/costings/$id/revise', data: draft.toJson());
    return Costing.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Costing> submitForApproval(int id) async {
    final response = await _dio.post('/costings/$id/submit');
    return Costing.fromJson(response.data as Map<String, dynamic>);
  }
}

final costingRepositoryProvider = Provider<CostingRepository>((ref) {
  return CostingRepositoryImpl(ref.watch(apiDioProvider));
});
