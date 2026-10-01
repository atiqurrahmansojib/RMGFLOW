import 'auth_tokens.dart';

/// Document 12.2: domain layer defines the contract; data layer implements it.
/// Keeps AuthController ignorant of Dio/HTTP details.
abstract class AuthRepository {
  Future<AuthTokens> login({required String email, required String password, String? deviceInfo});
  Future<AuthTokens> refresh(String refreshToken);
  Future<void> logout(String refreshToken);
}
