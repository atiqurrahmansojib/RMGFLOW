import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../../document/domain/commercial_document.dart';
import '../../document/presentation/commercial_document_list_screen.dart';
import '../application/shipment_controller.dart';
import '../domain/shipment.dart';

/// Document 7 (#65-66): shipment detail — status-change actions and a link
/// into this shipment's commercial documents (packing list, invoice, BL, …).
class ShipmentDetailScreen extends ConsumerWidget {
  const ShipmentDetailScreen({super.key, required this.orderId, required this.shipment});

  final int orderId;
  final Shipment shipment;

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, ShipmentStatus s) async {
    final ok = await confirmAction(
      context,
      title: 'Mark as ${s.label}?',
      message: '${shipment.shipmentNo} will move from ${shipment.status.label} to ${s.label}.',
      confirmLabel: 'Mark ${s.label.toLowerCase()}',
      destructive: s == ShipmentStatus.delayed,
    );
    if (ok) ref.read(shipmentStatusControllerProvider.notifier).updateStatus(orderId, shipment.id, s);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(shipmentStatusControllerProvider, (previous, next) {
      if (next is ShipmentStatusFailed) {
        showErrorSnack(context, next.failure.message);
      } else if (next is ShipmentStatusSuccess) {
        // The shipment list underneath shows the confirmation and refreshes.
        Navigator.of(context).pop(true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(shipment.shipmentNo)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          GradientHeader.module(
            AppModules.shipment,
            eyebrow: shipment.partial ? 'Partial shipment' : 'Shipment',
            title: shipment.shipmentNo,
            subtitle: [
              if (shipment.portOfLoading != null) shipment.portOfLoading!,
              if (shipment.portOfDischarge != null) shipment.portOfDischarge!,
            ].join(' → '),
            trailing: StatusChip(shipment.status.apiValue, label: shipment.status.label),
            bottom: Wrap(
              spacing: AppSpacing.xxl,
              runSpacing: AppSpacing.md,
              children: [
                HeaderStat(value: fmtQty(shipment.quantityShipped), label: 'Pieces'),
                if (shipment.cartons != null) HeaderStat(value: fmtQty(shipment.cartons!), label: 'Cartons'),
                if (shipment.eta != null) HeaderStat(value: relativeDays(daysFromToday(shipment.eta)!), label: 'ETA'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader('Change status', icon: Icons.swap_horiz_rounded, accentColor: AppModules.shipment.color),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: ShipmentStatus.values
                      .where((s) => s != shipment.status)
                      .map((s) => ActionChip(
                            avatar:
                                Icon(AppStatus.resolve(s.apiValue).icon, size: 18, color: AppStatus.color(s.apiValue)),
                            label: Text(s.label),
                            onPressed: () => _changeStatus(context, ref, s),
                          ))
                      .toList(),
                ),
                SectionHeader('Cargo', icon: Icons.inventory_2_rounded, accentColor: AppModules.shipment.color),
                AppCard(
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'Quantity',
                        value: '${fmtQty(shipment.quantityShipped)} pcs${shipment.partial ? ' (partial)' : ''}',
                        emphasize: true,
                      ),
                      if (shipment.cartons != null) InfoRow(label: 'Cartons', value: fmtQty(shipment.cartons!)),
                      if (shipment.grossWeight != null)
                        InfoRow(label: 'Gross weight', value: '${shipment.grossWeight} kg'),
                      if (shipment.netWeight != null) InfoRow(label: 'Net weight', value: '${shipment.netWeight} kg'),
                      if (shipment.volumeCbm != null) InfoRow(label: 'Volume', value: '${shipment.volumeCbm} CBM'),
                    ],
                  ),
                ),
                SectionHeader('Schedule & logistics',
                    icon: Icons.route_rounded, accentColor: AppModules.shipment.color),
                AppCard(
                  child: Column(
                    children: [
                      InfoRow(
                          label: 'Shipment date',
                          value: shipment.shipmentDate == null ? null : formatApiDate(shipment.shipmentDate)),
                      InfoRow(label: 'ETD', value: shipment.etd == null ? null : formatApiDate(shipment.etd)),
                      InfoRow(label: 'ETA', value: shipment.eta == null ? null : formatApiDate(shipment.eta)),
                      InfoRow(label: 'Port of loading', value: shipment.portOfLoading),
                      InfoRow(label: 'Port of discharge', value: shipment.portOfDischarge),
                      if (shipment.shippingLine != null) InfoRow(label: 'Shipping line', value: shipment.shippingLine),
                      if (shipment.containerNo != null)
                        InfoRow(label: 'Container', value: shipment.containerNo, copyable: true),
                      if (shipment.blAwbNo != null)
                        InfoRow(label: 'B/L / AWB', value: shipment.blAwbNo, copyable: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  icon: Icons.description_outlined,
                  label: 'Shipment documents',
                  variant: ButtonVariant.tonal,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CommercialDocumentListScreen(
                        entityType: DocumentEntityType.shipment,
                        entityId: shipment.id,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
