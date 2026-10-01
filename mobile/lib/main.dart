import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'core/storage/secure_token_storage.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // Document 15.1/12.4: the one place a real FlutterSecureStorage is
        // constructed — everything else depends on the SecureTokenStorage
        // abstraction, not this package directly.
        secureTokenStorageProvider.overrideWithValue(
          SecureTokenStorage(const FlutterSecureStorage()),
        ),
      ],
      child: const RmgflowApp(),
    ),
  );
}

class RmgflowApp extends ConsumerWidget {
  const RmgflowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'RMGFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
