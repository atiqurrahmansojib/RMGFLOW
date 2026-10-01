import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_tokens.dart';

/// Document 11.2: talks to /api/v1/auth/*. Uses rawDioProvider deliberately —
/// these three calls must work without (and in refresh's case, instead of) a
/// valid access token (see core/network/api_client.dart doc comment).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthTokens> login({required String email, required String password, String? deviceInfo}) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
      'deviceInfo': deviceInfo,
    });
    return AuthTokens.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
    return AuthTokens.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(rawDioProvider));
});
