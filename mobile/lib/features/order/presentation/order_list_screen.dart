import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../application/order_list_controller.dart';
import '../domain/order.dart';
import 'order_detail_screen.dart';
import 'order_form_screen.dart';

/// Document 7 (#48): Order list — search by order no./PO/buyer, filter by
/// status (client-side over the loaded page).
class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  OrderStatus? _status;
  String _query = '';

  Future<void> _create() async {
    final created = await Navigator.of(context).push<Order>(MaterialPageRoute(builder: (_) => const OrderFormScreen()));
    if (!mounted) return;
    ref.read(orderListControllerProvider.notifier).refresh();
    if (created != null) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: created)));
      if (mounted) ref.read(orderListControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('New order'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: SearchField(hintText: 'Search order no., PO or buyer', onChanged: (v) => setState(() => _query = v)),
          ),
          FilterChipBar<OrderStatus>(
            values: OrderStatus.values,
            selected: _status,
            labelOf: (s) => s.label,
            allLabel: 'All statuses',
            onSelected: (s) => setState(() => _status = s),
          ),
          Expanded(
            child: switch (state) {
              OrderListLoading() => const LoadingView(),
              OrderListError(:final failure) => ErrorStateView(
                  failure: failure,
                  onRetry: () => ref.read(orderListControllerProvider.notifier).refresh(),
                ),
              OrderListLoaded(:final orders) when orders.isEmpty => EmptyStateView(
                  title: 'No orders yet',
                  message: "Create an order from the buyer's PO to start production follow-up.",
                  icon: Icons.receipt_long_outlined,
                  color: AppModules.orders.color,
                  actionLabel: 'New order',
                  onAction: _create,
                ),
              OrderListLoaded(:final orders) => Builder(builder: (context) {
                  final q = _query.trim().toLowerCase();
                  final visible = orders.where((o) {
                    if (_status != null && o.status != _status) return false;
                    if (q.isEmpty) return true;
                    final hay =
                        '${o.orderNo} ${o.buyerPoNo} ${lookupLabel(ref, buyerLookupProvider, o.buyerId)}'.toLowerCase();
                    return hay.contains(q);
                  }).toList();
                  return RefreshIndicator(
                    onRefresh: () => ref.read(orderListControllerProvider.notifier).refresh(),
                    child: visible.isEmpty
                        ? RefreshableEmpty(
                            child: EmptyStateView(
                              message: 'No orders match this search or filter.',
                              icon: Icons.search_off_rounded,
                              color: AppModules.orders.color,
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: AppSpacing.listWithFab,
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final order = visible[index];
                              final days = daysFromToday(order.exFactoryDate);
                              final open = order.status != OrderStatus.cancelled && order.status != OrderStatus.closed;
                              return AppCard(
                                accentColor: AppStatus.color(order.status.apiValue),
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)))
                                    .then((_) => ref.read(orderListControllerProvider.notifier).refresh()),
                                child: RecordRow(
                                  leading: IconBadge(icon: AppModules.orders.icon, color: AppModules.orders.color),
                                  title: order.orderNo,
                                  subtitle:
                                      '${lookupLabel(ref, buyerLookupProvider, order.buyerId, fallback: 'Buyer #${order.buyerId}')} · PO ${order.buyerPoNo}',
                                  meta: [
                                    fmtMoney(order.currency, order.totalValue),
                                    if (order.exFactoryDate != null) 'Ex-fty ${formatApiDate(order.exFactoryDate)}',
                                  ].join(' · '),
                                  trailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      StatusChip(order.status.apiValue, label: order.status.label, dense: true),
                                      if (days != null && open) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        TonePill(
                                          relativeDays(days),
                                          icon: Icons.local_shipping_outlined,
                                          color: days < 0
                                              ? AppColors.danger
                                              : days <= 14
                                                  ? AppColors.warning
                                                  : AppColors.success,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                }),
            },
          ),
        ],
      ),
    );
  }
}
