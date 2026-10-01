import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/application/auth_controller.dart';

/// Document 14.9 recommendation: this becomes the "What needs attention
/// today" landing view once dashboards (Phase 12) exist. Placeholder for
/// Phase 1 — just proves the authenticated shell/navigation/logout work.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RMGFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Signed in. Modules (buyers, styles, orders, T&A, …) land in later phases '
            'per docs/20-implementation-roadmap.md.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
