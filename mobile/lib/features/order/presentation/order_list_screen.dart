import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/order_list_controller.dart';
import 'order_detail_screen.dart';
import 'order_form_screen.dart';

/// Document 7 (#48): Order list.
class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OrderFormScreen()),
        ).then((_) => ref.read(orderListControllerProvider.notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        OrderListLoading() => const LoadingView(),
        OrderListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(orderListControllerProvider.notifier).refresh(),
          ),
        OrderListLoaded(:final orders) when orders.isEmpty =>
          const EmptyStateView(message: 'No orders yet. Tap + to create one.', icon: Icons.receipt_long_outlined),
        OrderListLoaded(:final orders) => RefreshIndicator(
            onRefresh: () => ref.read(orderListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text(order.orderNo),
                  subtitle: Text('PO ${order.buyerPoNo} · Buyer #${order.buyerId} · ${order.currency} ${order.totalValue.toStringAsFixed(2)}'),
                  trailing: Chip(label: Text(order.status.label)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                  ).then((_) => ref.read(orderListControllerProvider.notifier).refresh()),
                );
              },
            ),
          ),
      },
    );
  }
}
