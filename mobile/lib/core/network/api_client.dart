import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'access_token_holder.dart';

/// Document 12.4: two Dio instances by design.
///
/// `rawDioProvider` carries no auth header and is used ONLY by the auth
/// feature itself (login/refresh/logout) — if it also required a valid
/// access token, refreshing an expired token would be impossible.
///
/// `apiDioProvider` is for every other feature: it attaches the current
/// access token to every request. It does NOT auto-retry on 401 itself —
/// that would require this core network layer to depend on the auth
/// feature. Instead, `AuthController.callAuthorized` (features/auth) wraps
/// repository calls, catches a 401, refreshes once via `rawDioProvider`,
/// and retries — keeping the retry policy in the auth feature, not here.
final rawDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
});

final apiDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(accessTokenProvider);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));

  return dio;
});
