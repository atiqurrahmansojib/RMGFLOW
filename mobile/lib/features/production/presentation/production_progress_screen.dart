import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/production_controller.dart';
import 'production_update_form_screen.dart';

/// Document 7 (#52-53)/9.6/14.4: planned-vs-actual production progress —
/// every number shown is the server's cumulative rollup, never summed here.
class ProductionProgressScreen extends ConsumerWidget {
  const ProductionProgressScreen({super.key, required this.orderId});

  final int orderId;

  Widget _stageRow(String label, int qty, int orderQuantity) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$qty / $orderQuantity'),
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productionProgressControllerProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Production Progress')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductionUpdateFormScreen(orderId: orderId)),
        ).then((_) => ref.read(productionProgressControllerProvider(orderId).notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        ProductionProgressLoading() => const LoadingView(),
        ProductionProgressError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(productionProgressControllerProvider(orderId).notifier).refresh(),
          ),
        ProductionProgressLoaded(:final progress) => RefreshIndicator(
            onRefresh: () => ref.read(productionProgressControllerProvider(orderId).notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order quantity: ${progress.orderQuantity}', style: Theme.of(context).textTheme.titleMedium),
                        const Divider(height: 24),
                        _stageRow('Cutting', progress.cumulativeCutting, progress.orderQuantity),
                        _stageRow('Sewing', progress.cumulativeSewing, progress.orderQuantity),
                        _stageRow('Finishing', progress.cumulativeFinishing, progress.orderQuantity),
                        _stageRow('Packing', progress.cumulativePacking, progress.orderQuantity),
                        _stageRow('Rejection', progress.cumulativeRejection, progress.orderQuantity),
                        _stageRow('Alteration', progress.cumulativeAlteration, progress.orderQuantity),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: (progress.packingProgressPercent / 100).clamp(0, 1)),
                        const SizedBox(height: 4),
                        Text('Packing progress: ${progress.packingProgressPercent.toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Daily Updates', style: Theme.of(context).textTheme.titleMedium),
                ...progress.dailyUpdates.map((u) => Card(
                      child: ListTile(
                        title: Text(u.updateDate),
                        subtitle: Text(
                          'Cut ${u.cuttingQty} · Sew ${u.sewingQty} · Finish ${u.finishingQty} · '
                          'Pack ${u.packingQty} · Reject ${u.rejectionQty} · Alter ${u.alterationQty}',
                        ),
                      ),
                    )),
              ],
            ),
          ),
      },
    );
  }
}
