import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/buyer.dart';
import '../domain/buyer_repository.dart';

/// Document 11.2: talks to /api/v1/buyers via the AUTHORIZED Dio client
/// (apiDioProvider) — unlike auth's own repository, every buyer endpoint
/// requires a valid access token (Doc 5.2 BUYER_VIEW/BUYER_MANAGE).
class BuyerRepositoryImpl implements BuyerRepository {
  BuyerRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Buyer>> list({String? search, int page = 0, int size = 25}) async {
    final response = await _dio.get('/buyers', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'size': size,
    });
    final content = (response.data as Map<String, dynamic>)['content'] as List;
    return content.map((e) => Buyer.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Buyer> get(int id) async {
    final response = await _dio.get('/buyers/$id');
    return Buyer.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Buyer> create(BuyerDraft draft) async {
    final response = await _dio.post('/buyers', data: draft.toJson());
    return Buyer.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Buyer> update(int id, BuyerDraft draft) async {
    final response = await _dio.put('/buyers/$id', data: draft.toJson());
    return Buyer.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deactivate(int id) async {
    await _dio.delete('/buyers/$id');
  }
}

final buyerRepositoryProvider = Provider<BuyerRepository>((ref) {
  return BuyerRepositoryImpl(ref.watch(apiDioProvider));
});
