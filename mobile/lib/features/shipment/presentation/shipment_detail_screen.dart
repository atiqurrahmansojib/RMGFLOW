import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(shipmentStatusControllerProvider, (previous, next) {
      if (next is ShipmentStatusFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      } else if (next is ShipmentStatusSuccess) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(shipment.shipmentNo)),
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
                      Text(shipment.shipmentNo, style: Theme.of(context).textTheme.titleMedium),
                      Chip(label: Text(shipment.status.label)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Quantity: ${shipment.quantityShipped}${shipment.partial ? ' (partial)' : ''}'),
                  if (shipment.cartons != null) Text('Cartons: ${shipment.cartons}'),
                  if (shipment.shipmentDate != null) Text('Shipment date: ${shipment.shipmentDate}'),
                  if (shipment.etd != null) Text('ETD: ${shipment.etd}'),
                  if (shipment.eta != null) Text('ETA: ${shipment.eta}'),
                  if (shipment.portOfLoading != null) Text('POL: ${shipment.portOfLoading}'),
                  if (shipment.portOfDischarge != null) Text('POD: ${shipment.portOfDischarge}'),
                  if (shipment.containerNo != null) Text('Container: ${shipment.containerNo}'),
                  if (shipment.blAwbNo != null) Text('BL/AWB: ${shipment.blAwbNo}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Change status', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: ShipmentStatus.values
                .where((s) => s != shipment.status)
                .map((s) => ActionChip(
                      label: Text(s.label),
                      onPressed: () =>
                          ref.read(shipmentStatusControllerProvider.notifier).updateStatus(orderId, shipment.id, s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.description_outlined),
            label: const Text('Shipment documents'),
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
    );
  }
}
