import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/access_token_holder.dart';
import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import 'auth_state.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  throw UnimplementedError('Override in main.dart with a real FlutterSecureStorage instance');
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref, ref.watch(authRepositoryProvider), ref.watch(secureTokenStorageProvider));
});

/// Document 12.3/15.1: owns the login/refresh/logout lifecycle and the
/// in-memory access token (accessTokenProvider). This is the ONLY place in
/// the app that writes to accessTokenProvider or the refresh token in secure
/// storage — every other feature just reads accessTokenProvider via the Dio
/// interceptor (core/network/api_client.dart).
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref, this._authRepository, this._tokenStorage) : super(const AuthInitial()) {
    _restoreSession();
  }

  final Ref _ref;
  final AuthRepository _authRepository;
  final SecureTokenStorage _tokenStorage;

  Future<void> _restoreSession() async {
    final storedRefreshToken = await _tokenStorage.readRefreshToken();
    if (storedRefreshToken == null) {
      state = const AuthUnauthenticated();
      return;
    }
    try {
      final tokens = await _authRepository.refresh(storedRefreshToken);
      await _tokenStorage.saveRefreshToken(tokens.refreshToken);
      _ref.read(accessTokenProvider.notifier).state = tokens.accessToken;
      state = const AuthAuthenticated();
    } on DioException {
      await _tokenStorage.clear();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login({required String email, required String password, String? deviceInfo}) async {
    state = const AuthLoading();
    try {
      final tokens = await _authRepository.login(email: email, password: password, deviceInfo: deviceInfo);
      await _tokenStorage.saveRefreshToken(tokens.refreshToken);
      _ref.read(accessTokenProvider.notifier).state = tokens.accessToken;
      state = const AuthAuthenticated();
    } on DioException catch (e) {
      state = AuthError(mapDioErrorToFailure(e));
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    _ref.read(accessTokenProvider.notifier).state = null;
    await _tokenStorage.clear();
    state = const AuthUnauthenticated();
    if (refreshToken != null) {
      // Best-effort server-side revoke (Doc 15.3) — local logout already happened,
      // so a failure here must never block the user from being signed out.
      try {
        await _authRepository.logout(refreshToken);
      } on DioException {
        // intentionally ignored
      }
    }
  }

  /// Document 12.4/12.5 recommendation: wraps a repository call that hit the
  /// authorized Dio client, retrying once after a silent refresh if the
  /// first attempt failed with 401. Keeps the retry policy in the auth
  /// feature rather than the core network layer.
  Future<T> callAuthorized<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) rethrow;
      final storedRefreshToken = await _tokenStorage.readRefreshToken();
      if (storedRefreshToken == null) {
        state = const AuthUnauthenticated();
        rethrow;
      }
      try {
        final tokens = await _authRepository.refresh(storedRefreshToken);
        await _tokenStorage.saveRefreshToken(tokens.refreshToken);
        _ref.read(accessTokenProvider.notifier).state = tokens.accessToken;
        return await call();
      } on DioException {
        await _tokenStorage.clear();
        _ref.read(accessTokenProvider.notifier).state = null;
        state = const AuthUnauthenticated();
        rethrow;
      }
    }
  }
}
