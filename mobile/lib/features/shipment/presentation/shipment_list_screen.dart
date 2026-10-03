import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/shipment_controller.dart';
import 'shipment_detail_screen.dart';
import 'shipment_form_screen.dart';

/// Document 7 (#65): one order's shipments, including partials.
class ShipmentListScreen extends ConsumerWidget {
  const ShipmentListScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shipmentListControllerProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Shipments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ShipmentFormScreen(orderId: orderId)),
        ).then((_) => ref.read(shipmentListControllerProvider(orderId).notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        ShipmentListLoading() => const LoadingView(),
        ShipmentListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(shipmentListControllerProvider(orderId).notifier).refresh(),
          ),
        ShipmentListLoaded(:final shipments) when shipments.isEmpty =>
          const EmptyStateView(message: 'No shipments yet. Tap + to create one.', icon: Icons.local_shipping_outlined),
        ShipmentListLoaded(:final shipments) => RefreshIndicator(
            onRefresh: () => ref.read(shipmentListControllerProvider(orderId).notifier).refresh(),
            child: ListView.separated(
              itemCount: shipments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final shipment = shipments[index];
                return ListTile(
                  title: Text(shipment.shipmentNo),
                  subtitle: Text('Qty ${shipment.quantityShipped}${shipment.partial ? ' (partial)' : ''}'),
                  trailing: Chip(label: Text(shipment.status.label)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ShipmentDetailScreen(orderId: orderId, shipment: shipment)),
                  ).then((_) => ref.read(shipmentListControllerProvider(orderId).notifier).refresh()),
                );
              },
            ),
          ),
      },
    );
  }
}
