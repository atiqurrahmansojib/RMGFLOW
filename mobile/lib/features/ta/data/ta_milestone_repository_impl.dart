import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/ta_milestone.dart';
import '../domain/ta_milestone_repository.dart';

/// Document 11.2: talks to /api/v1/orders/{orderId}/ta-milestones — requires
/// TA_VIEW/TA_UPDATE/TA_TEMPLATE_MANAGE (Doc 5.2). Status is always what the
/// server derived (Doc 9.5) — this layer never computes it.
class TaMilestoneRepositoryImpl implements TaMilestoneRepository {
  TaMilestoneRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<TaMilestone>> list(int orderId) async {
    final response = await _dio.get('/orders/$orderId/ta-milestones');
    return (response.data as List).map((e) => TaMilestone.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Document A15: usually auto-generated on order confirmation; this is the
  /// manual fallback for templates added/corrected after the fact.
  @override
  Future<List<TaMilestone>> generate(int orderId, int styleId) async {
    final response = await _dio.post('/orders/$orderId/ta-milestones/generate', queryParameters: {'styleId': styleId});
    return (response.data as List).map((e) => TaMilestone.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<TaMilestone> recordActualDate(int orderId, int milestoneId, RecordActualDateDraft draft) async {
    final response =
        await _dio.post('/orders/$orderId/ta-milestones/$milestoneId/actual-date', data: draft.toJson());
    return TaMilestone.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TaMilestone> assignResponsibleUser(int orderId, int milestoneId, int userId) async {
    final response = await _dio.post(
      '/orders/$orderId/ta-milestones/$milestoneId/responsible-user',
      queryParameters: {'userId': userId},
    );
    return TaMilestone.fromJson(response.data as Map<String, dynamic>);
  }
}

final taMilestoneRepositoryProvider = Provider<TaMilestoneRepository>((ref) {
  return TaMilestoneRepositoryImpl(ref.watch(apiDioProvider));
});
