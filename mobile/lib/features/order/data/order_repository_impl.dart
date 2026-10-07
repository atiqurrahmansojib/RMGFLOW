import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/order.dart';
import '../domain/order_repository.dart';

/// Document 11.2: talks to /api/v1/orders — requires ORDER_VIEW/ORDER_CREATE/
/// ORDER_CANCEL_APPROVE/ORDER_AMEND_REQUEST/ORDER_AMEND_APPROVE (Doc 5.2).
/// Order creation enforces the factory-buyer-approval gate server-side
/// (Doc 9.4) — a 400 with override hint surfaces via Failure/SnackBar.
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Order>> list({int? buyerId, OrderStatus? status, int page = 0, int size = 100}) async {
    final response = await _dio.get('/orders', queryParameters: {
      if (buyerId != null) 'buyerId': buyerId,
      if (status != null) 'status': status.apiValue,
      'page': page,
      'size': size,
      // Newest first, so client-side search/filter covers recent work.
      'sort': 'id,desc',
    });
    final content = (response.data as Map<String, dynamic>)['content'] as List;
    return content.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Order> get(int id) async {
    final response = await _dio.get('/orders/$id');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Order> create(OrderDraft draft) async {
    final response = await _dio.post('/orders', data: draft.toJson());
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> cancel(int id, String reason) async {
    await _dio.post('/orders/$id/cancel', queryParameters: {'reason': reason});
  }

  @override
  Future<List<OrderAmendment>> listAmendments(int orderId) async {
    final response = await _dio.get('/orders/$orderId/amendments');
    return (response.data as List).map((e) => OrderAmendment.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<OrderAmendment> requestAmendment(int orderId, OrderAmendmentDraft draft) async {
    final response = await _dio.post('/orders/$orderId/amendments', data: draft.toJson());
    return OrderAmendment.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<OrderAmendment> approveAmendment(int orderId, int amendmentId) async {
    final response = await _dio.post('/orders/$orderId/amendments/$amendmentId/approve');
    return OrderAmendment.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<OrderAmendment> rejectAmendment(int orderId, int amendmentId) async {
    final response = await _dio.post('/orders/$orderId/amendments/$amendmentId/reject');
    return OrderAmendment.fromJson(response.data as Map<String, dynamic>);
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(apiDioProvider));
});
