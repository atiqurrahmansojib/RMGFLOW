import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/factory.dart';
import '../domain/factory_repository.dart';

class FactoryRepositoryImpl implements FactoryRepository {
  FactoryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Factory>> list({PartnerType? partnerType}) async {
    final response = await _dio.get('/factories', queryParameters: {
      if (partnerType != null) 'partnerType': partnerType.apiValue,
      'size': 200,
    });
    final content = (response.data as Map<String, dynamic>)['content'] as List;
    return content.map((e) => Factory.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Factory> create(FactoryDraft draft) async {
    final response = await _dio.post('/factories', data: draft.toJson());
    return Factory.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Factory> update(int id, FactoryDraft draft) async {
    final response = await _dio.put('/factories/$id', data: draft.toJson());
    return Factory.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deactivate(int id) async {
    await _dio.delete('/factories/$id');
  }
}

final factoryRepositoryProvider = Provider<FactoryRepository>((ref) {
  return FactoryRepositoryImpl(ref.watch(apiDioProvider));
});
