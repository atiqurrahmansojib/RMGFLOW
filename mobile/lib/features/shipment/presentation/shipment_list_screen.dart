import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../application/shipment_controller.dart';
import '../domain/shipment.dart';
import 'shipment_detail_screen.dart';
import 'shipment_form_screen.dart';

/// Document 7 (#65): one order's shipments, including partials.
class ShipmentListScreen extends ConsumerWidget {
  const ShipmentListScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shipmentListControllerProvider(orderId));
    void refresh() => ref.read(shipmentListControllerProvider(orderId).notifier).refresh();
    ref.listen(shipmentStatusControllerProvider, (previous, next) {
      if (next is ShipmentStatusFailed) showErrorSnack(context, next.failure.message);
      if (next is ShipmentStatusSuccess) {
        showSuccessSnack(context, '${next.shipment.shipmentNo} is now ${next.shipment.status.label.toLowerCase()}');
        refresh();
      }
    });
    Future<void> open(Shipment shipment) async {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ShipmentDetailScreen(orderId: orderId, shipment: shipment)));
      if (context.mounted) refresh();
    }

    Future<void> create() async {
      final created = await Navigator.of(context)
          .push<Shipment>(MaterialPageRoute(builder: (_) => ShipmentFormScreen(orderId: orderId)));
      if (!context.mounted) return;
      refresh();
      if (created != null) await open(created);
    }

    Future<void> changeStatus(Shipment shipment, ShipmentStatus status) async {
      if (status == ShipmentStatus.delayed) {
        final ok = await confirmAction(
          context,
          title: 'Mark ${shipment.shipmentNo} as delayed?',
          message: 'The buyer-facing status will show this shipment as delayed.',
          confirmLabel: 'Mark delayed',
          destructive: true,
        );
        if (!ok) return;
      }
      ref.read(shipmentStatusControllerProvider.notifier).updateStatus(orderId, shipment.id, status);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shipments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: create,
        icon: const Icon(Icons.add),
        label: const Text('New shipment'),
      ),
      body: switch (state) {
        ShipmentListLoading() => const LoadingView(),
        ShipmentListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(shipmentListControllerProvider(orderId).notifier).refresh(),
          ),
        ShipmentListLoaded(:final shipments) when shipments.isEmpty => EmptyStateView(
            title: 'No shipments yet',
            message: 'Book the first shipment once goods pass final inspection.',
            icon: Icons.local_shipping_outlined,
            color: AppModules.shipment.color,
            actionLabel: 'New shipment',
            onAction: create,
          ),
        ShipmentListLoaded(:final shipments) => RefreshIndicator(
            onRefresh: () => ref.read(shipmentListControllerProvider(orderId).notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.listWithFab.copyWith(left: 0, right: 0, top: 0),
              children: [
                GradientHeader.module(
                  AppModules.shipment,
                  eyebrow: 'Shipments',
                  title: '${fmtQty(shipments.fold<int>(0, (s, x) => s + x.quantityShipped))} pcs shipped',
                  subtitle: '${shipments.length} shipment${shipments.length == 1 ? '' : 's'}',
                  bottom: Row(
                    children: [
                      HeaderStat(
                          value: '${shipments.where((x) => x.status == ShipmentStatus.inTransit).length}',
                          label: 'In transit'),
                      const SizedBox(width: AppSpacing.xxl),
                      HeaderStat(
                          value: '${shipments.where((x) => x.status == ShipmentStatus.delivered).length}',
                          label: 'Delivered'),
                      const SizedBox(width: AppSpacing.xxl),
                      HeaderStat(
                          value: '${shipments.where((x) => x.status == ShipmentStatus.delayed).length}',
                          label: 'Delayed'),
                    ],
                  ),
                ),
                for (final shipment in shipments)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AppCard(
                      accentColor: AppStatus.color(shipment.status.apiValue),
                      onTap: () => open(shipment),
                      child: RecordRow(
                        leading: IconBadge(icon: AppModules.shipment.icon, color: AppModules.shipment.color),
                        title: shipment.shipmentNo,
                        subtitle: '${fmtQty(shipment.quantityShipped)} pcs${shipment.partial ? ' (partial)' : ''}'
                            '${shipment.cartons != null ? ' · ${shipment.cartons} ctns' : ''}',
                        meta: [
                          if (shipment.etd != null) 'ETD ${formatApiDate(shipment.etd)}',
                          if (shipment.eta != null) 'ETA ${formatApiDate(shipment.eta)}',
                          if (shipment.portOfDischarge != null) '→ ${shipment.portOfDischarge}',
                        ].join(' · '),
                        trailing: StatusMenuChip<ShipmentStatus>(
                          status: shipment.status.apiValue,
                          label: shipment.status.label,
                          options: ShipmentStatus.values.where((x) => x != shipment.status).toList(),
                          apiOf: (x) => x.apiValue,
                          labelOf: (x) => 'Mark ${x.label.toLowerCase()}',
                          onSelected: (x) => changeStatus(shipment, x),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      },
    );
  }
}
