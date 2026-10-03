import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/production_repository.dart';
import '../domain/production_update.dart';

/// Document 11.2: talks to /api/v1/orders/{orderId}/production-updates —
/// requires PRODUCTION_VIEW/PRODUCTION_UPDATE (Doc 5.2). The packing
/// hard-block (packing can never exceed order quantity) is enforced
/// server-side; a 400 here surfaces via Failure/SnackBar like any other
/// validation error.
class ProductionRepositoryImpl implements ProductionRepository {
  ProductionRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<ProductionProgress> progress(int orderId) async {
    final response = await _dio.get('/orders/$orderId/production-updates');
    return ProductionProgress.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProductionUpdate> recordDailyUpdate(int orderId, ProductionUpdateDraft draft) async {
    final response = await _dio.post('/orders/$orderId/production-updates', data: draft.toJson());
    return ProductionUpdate.fromJson(response.data as Map<String, dynamic>);
  }
}

final productionRepositoryProvider = Provider<ProductionRepository>((ref) {
  return ProductionRepositoryImpl(ref.watch(apiDioProvider));
});
