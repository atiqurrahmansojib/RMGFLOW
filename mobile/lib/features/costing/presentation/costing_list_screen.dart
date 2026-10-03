import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/costing_list_controller.dart';
import '../domain/costing.dart';
import 'costing_detail_screen.dart';
import 'costing_form_screen.dart';

/// Document 7 (#37): Costing list — shows version, status, and server-computed
/// margin for each style's costing history.
class CostingListScreen extends ConsumerWidget {
  const CostingListScreen({super.key, this.styleId});

  final int? styleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(costingListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Costings')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CostingFormScreen(initialStyleId: styleId)),
        ).then((_) => ref.read(costingListControllerProvider.notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        CostingListLoading() => const LoadingView(),
        CostingListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(costingListControllerProvider.notifier).refresh(),
          ),
        CostingListLoaded(:final costings) when costings.isEmpty =>
          const EmptyStateView(message: 'No costings yet. Tap + to add one.', icon: Icons.calculate_outlined),
        CostingListLoaded(:final costings) => RefreshIndicator(
            onRefresh: () => ref.read(costingListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: costings.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final costing = costings[index];
                return ListTile(
                  title: Text('Style #${costing.styleId} · v${costing.versionNo}'),
                  subtitle: Text(
                    '${costing.currency} ${costing.totalCost.toStringAsFixed(2)}'
                    '${costing.marginPercent != null ? ' · margin ${costing.marginPercent!.toStringAsFixed(1)}%' : ''}',
                  ),
                  trailing: Chip(label: Text(costing.status.label)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CostingDetailScreen(costingId: costing.id)),
                  ).then((_) => ref.read(costingListControllerProvider.notifier).refresh()),
                );
              },
            ),
          ),
      },
    );
  }
}
