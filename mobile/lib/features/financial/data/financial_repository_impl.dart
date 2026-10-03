import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/financial.dart';
import '../domain/financial_repository.dart';

/// Document 11.2: talks to /api/v1/orders/{orderId}/financials, /receivables,
/// /payables, and /api/v1/payment-records — requires FINANCIAL_VIEW/
/// FINANCIAL_MANAGE (Doc 5.2). Every derived status/margin shown is exactly
/// what the server returned.
class FinancialRepositoryImpl implements FinancialRepository {
  FinancialRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<OrderFinancials> getFinancials(int orderId) async {
    final response = await _dio.get('/orders/$orderId/financials');
    return OrderFinancials.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<OrderFinancials> upsertFinancials(int orderId, OrderFinancialsDraft draft) async {
    final response = await _dio.put('/orders/$orderId/financials', data: draft.toJson());
    return OrderFinancials.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<Receivable>> listReceivablesByOrder(int orderId) async {
    final response = await _dio.get('/orders/$orderId/receivables');
    return (response.data as List).map((e) => Receivable.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Receivable>> listAllReceivables() async {
    final response = await _dio.get('/receivables');
    return (response.data as List).map((e) => Receivable.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Receivable> createReceivable(int orderId, ReceivableDraft draft) async {
    final response = await _dio.post('/orders/$orderId/receivables', data: draft.toJson());
    return Receivable.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<Payable>> listPayablesByOrder(int orderId) async {
    final response = await _dio.get('/orders/$orderId/payables');
    return (response.data as List).map((e) => Payable.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Payable>> listAllPayables() async {
    final response = await _dio.get('/payables');
    return (response.data as List).map((e) => Payable.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Payable> createPayable(int orderId, PayableDraft draft) async {
    final response = await _dio.post('/orders/$orderId/payables', data: draft.toJson());
    return Payable.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> recordPayment(PaymentRecordDraft draft) async {
    await _dio.post('/payment-records', data: draft.toJson());
  }
}

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  return FinancialRepositoryImpl(ref.watch(apiDioProvider));
});
