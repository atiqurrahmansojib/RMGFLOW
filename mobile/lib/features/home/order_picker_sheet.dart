import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets/widgets.dart';
import '../auth/application/auth_controller.dart';
import '../order/data/order_repository_impl.dart';
import '../order/domain/order.dart';

/// Home shortcut for order-scoped modules (T&A, production, quality, ...):
/// one searchable sheet to pick the order, then straight into that module —
/// instead of Orders list -> order detail -> module.
Future<Order?> pickOrder(BuildContext context, AppModule module) {
  return showModalBottomSheet<Order>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _OrderPickerSheet(module: module),
  );
}

final _pickerOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref
      .read(authControllerProvider.notifier)
      .callAuthorized(() => ref.read(orderRepositoryProvider).list(size: 100));
});

class _OrderPickerSheet extends ConsumerStatefulWidget {
  const _OrderPickerSheet({required this.module});
  final AppModule module;

  @override
  ConsumerState<_OrderPickerSheet> createState() => _OrderPickerSheetState();
}

class _OrderPickerSheetState extends ConsumerState<_OrderPickerSheet> {
  String _query = '';

  bool _matches(Order o) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return o.orderNo.toLowerCase().contains(q) || o.buyerPoNo.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(_pickerOrdersProvider);
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(widget.module.icon, color: widget.module.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${widget.module.label}: choose an order', style: theme.textTheme.titleMedium),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchField(
              hintText: 'Search order no. or buyer PO',
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: orders.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(
                child: TextButton.icon(
                  onPressed: () => ref.invalidate(_pickerOrdersProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Could not load orders. Try again'),
                ),
              ),
              data: (all) {
                final list = all.where(_matches).toList();
                if (list.isEmpty) {
                  return const EmptyStateView(message: 'No matching orders.', icon: Icons.receipt_long_outlined);
                }
                return ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final o = list[i];
                    return AppCard(
                      accentColor: AppStatus.color(o.status.name),
                      onTap: () => Navigator.of(context).pop(o),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.orderNo, style: theme.textTheme.titleSmall),
                                const SizedBox(height: 2),
                                Text(
                                  'PO ${o.buyerPoNo}${o.exFactoryDate != null ? ' · Ex-factory ${o.exFactoryDate}' : ''}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(o.status.name, dense: true),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
