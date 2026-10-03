import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/quotation.dart';
import '../domain/quotation_repository.dart';

/// Document 11.2: talks to /api/v1/quotations — requires QUOTATION_VIEW/
/// QUOTATION_MANAGE (Doc 5.2); creation requires an APPROVED costing, enforced
/// server-side, so a 400 here reads back as a ValidationFailure.
class QuotationRepositoryImpl implements QuotationRepository {
  QuotationRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Quotation>> list({int? buyerId, int page = 0, int size = 25}) async {
    final response = await _dio.get('/quotations', queryParameters: {
      if (buyerId != null) 'buyerId': buyerId,
      'page': page,
      'size': size,
    });
    final content = (response.data as Map<String, dynamic>)['content'] as List;
    return content.map((e) => Quotation.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Quotation> get(int id) async {
    final response = await _dio.get('/quotations/$id');
    return Quotation.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Quotation> create(QuotationDraft draft) async {
    final response = await _dio.post('/quotations', data: draft.toJson());
    return Quotation.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Quotation> createRevision(int id, QuotationDraft draft) async {
    final response = await _dio.post('/quotations/$id/revise', data: draft.toJson());
    return Quotation.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Quotation> updateStatus(int id, QuotationStatus status) async {
    final response = await _dio.post('/quotations/$id/status', queryParameters: {'status': status.apiValue});
    return Quotation.fromJson(response.data as Map<String, dynamic>);
  }
}

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  return QuotationRepositoryImpl(ref.watch(apiDioProvider));
});
