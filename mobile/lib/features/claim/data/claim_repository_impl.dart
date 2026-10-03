import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/claim.dart';
import '../domain/claim_repository.dart';

/// Document 11.2: talks to /api/v1/claims(+ /orders/{orderId}/claims) —
/// requires CLAIM_VIEW/CLAIM_MANAGE (Doc 5.2).
class ClaimRepositoryImpl implements ClaimRepository {
  ClaimRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Claim>> listByOrder(int orderId) async {
    final response = await _dio.get('/orders/$orderId/claims');
    return (response.data as List).map((e) => Claim.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Claim>> listAll() async {
    final response = await _dio.get('/claims');
    return (response.data as List).map((e) => Claim.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Claim> create(int orderId, ClaimDraft draft) async {
    final response = await _dio.post('/orders/$orderId/claims', data: draft.toJson());
    return Claim.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Claim> resolve(int id, ClaimResolutionDraft draft) async {
    final response = await _dio.post('/claims/$id/resolve', data: draft.toJson());
    return Claim.fromJson(response.data as Map<String, dynamic>);
  }
}

final claimRepositoryProvider = Provider<ClaimRepository>((ref) {
  return ClaimRepositoryImpl(ref.watch(apiDioProvider));
});
