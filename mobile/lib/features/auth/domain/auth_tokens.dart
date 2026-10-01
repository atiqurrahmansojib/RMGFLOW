/// Mirrors backend TokenResponse (com.rmgflow.identity.dto.TokenResponse, Doc 11.2).
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        accessTokenExpiresInSeconds: json['accessTokenExpiresInSeconds'] as int,
      );

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
}
