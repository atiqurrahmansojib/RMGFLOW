import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/shipment.dart';
import '../domain/shipment_repository.dart';

/// Document 11.2: talks to /api/v1/orders/{orderId}/shipments — requires
/// SHIPMENT_VIEW/SHIPMENT_MANAGE (Doc 5.2). Creation enforces three
/// server-side gates (Doc 9.7/9.8/9.11 #5); a 400 surfaces via Failure/SnackBar.
class ShipmentRepositoryImpl implements ShipmentRepository {
  ShipmentRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Shipment>> list(int orderId) async {
    final response = await _dio.get('/orders/$orderId/shipments');
    return (response.data as List).map((e) => Shipment.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Shipment> create(int orderId, ShipmentDraft draft) async {
    final response = await _dio.post('/orders/$orderId/shipments', data: draft.toJson());
    return Shipment.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Shipment> updateStatus(int orderId, int shipmentId, ShipmentStatus status) async {
    final response = await _dio.post(
      '/orders/$orderId/shipments/$shipmentId/status',
      queryParameters: {'status': status.apiValue},
    );
    return Shipment.fromJson(response.data as Map<String, dynamic>);
  }
}

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  return ShipmentRepositoryImpl(ref.watch(apiDioProvider));
});
