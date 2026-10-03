import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/shipment_controller.dart';
import '../domain/shipment.dart';

/// Document 7 (#65): create a shipment. The three server-side gates (Doc
/// 9.7/9.8/9.11 #5 — quality, quantity-never-exceeds-order, partial
/// authorization) are never evaluated here; the quality-gate override toggle
/// only matters for a user holding the relevant override permission.
class ShipmentFormScreen extends ConsumerStatefulWidget {
  const ShipmentFormScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ShipmentFormScreen> createState() => _ShipmentFormScreenState();
}

class _ShipmentFormScreenState extends ConsumerState<ShipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _cartonsController = TextEditingController();
  final _portOfLoadingController = TextEditingController();
  final _portOfDischargeController = TextEditingController();
  final _shippingLineController = TextEditingController();
  final _containerNoController = TextEditingController();
  final _blAwbNoController = TextEditingController();
  final _overrideReasonController = TextEditingController();
  DateTime? _shipmentDate;
  DateTime? _etd;
  DateTime? _eta;
  bool _overrideQualityGate = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _cartonsController.dispose();
    _portOfLoadingController.dispose();
    _portOfDischargeController.dispose();
    _shippingLineController.dispose();
    _containerNoController.dispose();
    _blAwbNoController.dispose();
    _overrideReasonController.dispose();
    super.dispose();
  }

  String? _iso(DateTime? d) => d?.toIso8601String().split('T').first;

  Future<void> _pickDate(void Function(DateTime) onPicked) async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => onPicked(picked));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = ShipmentDraft(
      shipmentDate: _iso(_shipmentDate),
      etd: _iso(_etd),
      eta: _iso(_eta),
      quantityShipped: int.parse(_quantityController.text.trim()),
      cartons: int.tryParse(_cartonsController.text.trim()),
      portOfLoading: _portOfLoadingController.text.trim().isEmpty ? null : _portOfLoadingController.text.trim(),
      portOfDischarge: _portOfDischargeController.text.trim().isEmpty ? null : _portOfDischargeController.text.trim(),
      shippingLine: _shippingLineController.text.trim().isEmpty ? null : _shippingLineController.text.trim(),
      containerNo: _containerNoController.text.trim().isEmpty ? null : _containerNoController.text.trim(),
      blAwbNo: _blAwbNoController.text.trim().isEmpty ? null : _blAwbNoController.text.trim(),
      overrideQualityGate: _overrideQualityGate,
      overrideReason: _overrideReasonController.text.trim().isEmpty ? null : _overrideReasonController.text.trim(),
    );
    ref.read(shipmentFormControllerProvider.notifier).submit(widget.orderId, draft);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(shipmentFormControllerProvider, (previous, next) {
      if (next is ShipmentFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is ShipmentFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(shipmentFormControllerProvider);
    final isSubmitting = formState is ShipmentFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('New Shipment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _quantityController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity Shipped'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cartonsController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cartons (optional)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Shipment date'),
              subtitle: Text(_iso(_shipmentDate) ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSubmitting ? null : () => _pickDate((d) => _shipmentDate = d),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ETD'),
              subtitle: Text(_iso(_etd) ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSubmitting ? null : () => _pickDate((d) => _etd = d),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ETA'),
              subtitle: Text(_iso(_eta) ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSubmitting ? null : () => _pickDate((d) => _eta = d),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _portOfLoadingController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Port of loading (optional)'),
            ),
            TextFormField(
              controller: _portOfDischargeController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Port of discharge (optional)'),
            ),
            TextFormField(
              controller: _shippingLineController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Shipping line (optional)'),
            ),
            TextFormField(
              controller: _containerNoController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Container No (optional)'),
            ),
            TextFormField(
              controller: _blAwbNoController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'BL/AWB No (optional)'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Override quality gate'),
              subtitle: const Text('Requires the shipment quality-gate override permission'),
              value: _overrideQualityGate,
              onChanged: isSubmitting ? null : (v) => setState(() => _overrideQualityGate = v),
            ),
            if (_overrideQualityGate)
              TextFormField(
                controller: _overrideReasonController,
                enabled: !isSubmitting,
                decoration: const InputDecoration(labelText: 'Override reason'),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create shipment'),
            ),
          ],
        ),
      ),
    );
  }
}
