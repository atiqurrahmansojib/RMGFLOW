/// Document 17.8: environment-specific config injected at build/run time,
/// never hardcoded. Pass via --dart-define, e.g.:
///   flutter run --dart-define=API_BASE_URL=https://api.rmgflow.example/api/v1
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1', // Android emulator -> host localhost
  );
}
