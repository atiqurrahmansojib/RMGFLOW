import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/style.dart';
import '../domain/style_repository.dart';

class StyleRepositoryImpl implements StyleRepository {
  StyleRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Style>> list({String? search}) async {
    final response = await _dio.get('/styles', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final content = (response.data as Map<String, dynamic>)['content'] as List;
    return content.map((e) => Style.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Style> create(StyleDraft draft) async {
    final response = await _dio.post('/styles', data: draft.toJson());
    return Style.fromJson(response.data as Map<String, dynamic>);
  }
}

final styleRepositoryProvider = Provider<StyleRepository>((ref) {
  return StyleRepositoryImpl(ref.watch(apiDioProvider));
});
