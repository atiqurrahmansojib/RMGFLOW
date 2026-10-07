// Smoke test: app boots to the login screen when no refresh token is stored.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rmgflow_mobile/core/storage/secure_token_storage.dart';
import 'package:rmgflow_mobile/features/auth/application/auth_controller.dart';
import 'package:rmgflow_mobile/main.dart';

class FakeSecureTokenStorage implements SecureTokenStorage {
  @override
  Future<void> saveRefreshToken(String cookie) async {}

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('App boots to the login screen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(
            FakeSecureTokenStorage(),
          ),
        ],
        child: const RmgflowApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
  });
}
