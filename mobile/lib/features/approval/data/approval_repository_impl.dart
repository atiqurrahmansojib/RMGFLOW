import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/approval.dart';
import '../domain/approval_repository.dart';

/// Document 11.2: talks to /api/v1/approvals — the single generic endpoint set
/// the Pending Approvals Inbox (#67) and Approval Detail/Action (#68) screens
/// use, regardless of target module (Doc ADR-08).
class ApprovalRepositoryImpl implements ApprovalRepository {
  ApprovalRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Approval>> inbox({ApprovalTargetType? targetType, int page = 0, int size = 25}) async {
    final response = await _dio.get('/approvals', queryParameters: {
      if (targetType != null) 'targetType': targetType.apiValue,
      'page': page,
      'size': size,
    });
    final content = (response.data as Map<String, dynamic>)['content'] as List;
    return content.map((e) => Approval.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Approval>> history({required ApprovalTargetType targetType, required int targetId}) async {
    final response = await _dio.get('/approvals/history', queryParameters: {
      'targetType': targetType.apiValue,
      'targetId': targetId,
    });
    return (response.data as List).map((e) => Approval.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Approval> decide(int approvalId, ApprovalDecision decision) async {
    final response = await _dio.post('/approvals/$approvalId/decide', data: decision.toJson());
    return Approval.fromJson(response.data as Map<String, dynamic>);
  }
}

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  return ApprovalRepositoryImpl(ref.watch(apiDioProvider));
});
