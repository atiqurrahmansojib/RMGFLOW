import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Document 15.1/12.4: refresh token lives in Android Keystore-backed secure
/// storage, never SharedPreferences. Access token is kept in memory only
/// (AuthController state), not persisted at all.
class SecureTokenStorage {
  SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _refreshTokenKey = 'rmgflow.refresh_token';

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clear() => _storage.delete(key: _refreshTokenKey);
}
