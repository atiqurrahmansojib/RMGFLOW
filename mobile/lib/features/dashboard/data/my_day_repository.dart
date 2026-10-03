import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/my_day.dart';

/// Document 11.2/14.9: talks to /api/v1/dashboard/my-day — authenticated-only,
/// no extra permission gate (every role gets a dashboard).
class MyDayRepository {
  MyDayRepository(this._dio);

  final Dio _dio;

  Future<MyDay> fetch() async {
    final response = await _dio.get('/dashboard/my-day');
    return MyDay.fromJson(response.data as Map<String, dynamic>);
  }
}

final myDayRepositoryProvider = Provider<MyDayRepository>((ref) {
  return MyDayRepository(ref.watch(apiDioProvider));
});
