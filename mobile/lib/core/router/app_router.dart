import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../common/widgets/loading_view.dart';

/// Document 12.2/12.7: redirect based on AuthController state so every screen
/// doesn't need its own "am I logged in" check. Also the attachment point
/// for Document 12.7's notification deep links once push is wired up
/// (Phase 12) — a notification payload resolves to a named route here.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      switch (authState) {
        case AuthInitial():
        case AuthLoading():
          return null; // stay put; splash/loading handled by the builder below
        case AuthAuthenticated():
          return loggingIn ? '/' : null;
        case AuthUnauthenticated():
        case AuthError():
          return loggingIn ? null : '/login';
      }
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _RootGate()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ],
  );
});

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is AuthAuthenticated) return const HomeScreen();
    return const Scaffold(body: LoadingView());
  }
}

/// Bridges Riverpod state changes into go_router's Listenable-based refresh API.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
