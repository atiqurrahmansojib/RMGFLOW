import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../claim/presentation/claim_list_screen.dart';
import '../../document/domain/commercial_document.dart';
import '../../document/presentation/commercial_document_list_screen.dart';
import '../../financial/presentation/order_financial_screen.dart';
import '../../production/presentation/production_progress_screen.dart';
import '../../quality/presentation/inspection_list_screen.dart';
import '../../shipment/presentation/shipment_list_screen.dart';
import '../../ta/presentation/ta_milestone_list_screen.dart';
import '../application/order_action_controller.dart';
import '../domain/order.dart';
import 'order_amendments_screen.dart';

/// Document 7 (#49-51): order detail — items, cancel action, amendment
/// history, and the entry point into this order's T&A calendar.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Order'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Cancellation reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Back')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true || reasonController.text.trim().isEmpty) return;
    await ref.read(orderActionControllerProvider.notifier).cancel(order.id, reasonController.text.trim());
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(orderActionControllerProvider, (previous, next) {
      if (next is OrderActionFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(order.orderNo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.orderNo, style: Theme.of(context).textTheme.titleMedium),
                      Chip(label: Text(order.status.label)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('PO: ${order.buyerPoNo} · Buyer #${order.buyerId}'),
                  if (order.quotationId != null) Text('Quotation #${order.quotationId}'),
                  Text('Order date: ${order.orderDate}'),
                  if (order.exFactoryDate != null) Text('Ex-factory: ${order.exFactoryDate}'),
                  if (order.deliveryDate != null) Text('Delivery: ${order.deliveryDate}'),
                  if (order.incoterm != null) Text('Incoterm: ${order.incoterm}'),
                  const Divider(height: 24),
                  Text(
                    'Total: ${order.currency} ${order.totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Items', style: Theme.of(context).textTheme.titleMedium),
          ...order.items.map((item) => Card(
                child: ListTile(
                  title: Text('Style #${item.styleId} · Factory #${item.factoryId}'),
                  subtitle: Text([
                    if (item.color != null) 'Color: ${item.color}',
                    if (item.size != null) 'Size: ${item.size}',
                    'Qty: ${item.quantity}',
                  ].join(' · ')),
                  trailing: Text(item.unitPrice.toStringAsFixed(2)),
                ),
              )),
          const SizedBox(height: 16),
          if (order.exFactoryDate != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.event_note_outlined),
              label: const Text('T&A Calendar'),
              onPressed: order.items.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaMilestoneListScreen(orderId: order.id, styleId: order.items.first.styleId),
                        ),
                      ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.trending_up_outlined),
            label: const Text('Production Progress'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProductionProgressScreen(orderId: order.id)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Inspections & Quality'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => InspectionListScreen(orderId: order.id)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Shipments'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ShipmentListScreen(orderId: order.id)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.description_outlined),
            label: const Text('Order Documents'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CommercialDocumentListScreen(entityType: DocumentEntityType.order, entityId: order.id),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Amendments'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrderAmendmentsScreen(orderId: order.id)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Financials'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrderFinancialScreen(orderId: order.id)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.gavel_outlined),
            label: const Text('Claims'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ClaimListScreen(orderId: order.id)),
            ),
          ),
          const SizedBox(height: 8),
          if (order.status != OrderStatus.cancelled && order.status != OrderStatus.closed)
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel order'),
              style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => _cancel(context, ref),
            ),
        ],
      ),
    );
  }
}
