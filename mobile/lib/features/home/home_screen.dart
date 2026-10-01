import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/application/auth_controller.dart';
import '../buyers/presentation/buyer_list_screen.dart';
import '../factories/presentation/factory_list_screen.dart';

/// Document 14.9 recommendation: this becomes the "What needs attention
/// today" landing view once dashboards (Phase 12) exist. For now (through
/// Phase 2) it's a simple module launcher — proves the authenticated shell
/// works and gives access to what's actually built so far.
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Buyers'),
              subtitle: const Text('Buyer master, contacts, requirements'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BuyerListScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.factory_outlined),
              title: const Text('Factories & Vendors'),
              subtitle: const Text('Factory master, capabilities, certifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FactoryListScreen()),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'More modules (inquiries, styles, orders, T&A, …) land in later phases '
              'per docs/20-implementation-roadmap.md.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
