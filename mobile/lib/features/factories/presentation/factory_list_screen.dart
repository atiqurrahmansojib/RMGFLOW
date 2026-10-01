import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/factory_list_controller.dart';
import '../domain/factory.dart';
import 'factory_form_screen.dart';

/// Document 7 (#20): Factory/Vendor List — filterable by partner type (Doc 6:
/// factory types "do not behave identically", so filtering by type matters).
class FactoryListScreen extends ConsumerWidget {
  const FactoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(factoryListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factories & Vendors'),
        actions: [
          PopupMenuButton<PartnerType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) => ref.read(factoryListControllerProvider.notifier).load(partnerType: type),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All types')),
              ...PartnerType.values.map((t) => PopupMenuItem(value: t, child: Text(t.label))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FactoryFormScreen()),
        ).then((_) => ref.read(factoryListControllerProvider.notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        FactoryListLoading() => const LoadingView(),
        FactoryListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(factoryListControllerProvider.notifier).refresh(),
          ),
        FactoryListLoaded(:final factories) when factories.isEmpty =>
          const EmptyStateView(message: 'No factories yet. Tap + to add one.', icon: Icons.factory_outlined),
        FactoryListLoaded(:final factories) => RefreshIndicator(
            onRefresh: () => ref.read(factoryListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: factories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final factory = factories[index];
                return ListTile(
                  title: Text(factory.name),
                  subtitle: Text('${factory.code} · ${factory.partnerType.label}'),
                  trailing: factory.active ? null : const Chip(label: Text('Inactive')),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FactoryFormScreen(existingFactory: factory)),
                  ).then((_) => ref.read(factoryListControllerProvider.notifier).refresh()),
                );
              },
            ),
          ),
      },
    );
  }
}
