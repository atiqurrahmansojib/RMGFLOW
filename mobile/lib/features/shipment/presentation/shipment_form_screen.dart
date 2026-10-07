import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/widgets.dart';
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
  final _grossWeightController = TextEditingController();
  final _netWeightController = TextEditingController();
  final _volumeController = TextEditingController();
  final _portOfLoadingController = TextEditingController(text: 'Chattogram');
  final _portOfDischargeController = TextEditingController();
  final _shippingLineController = TextEditingController();
  final _containerNoController = TextEditingController();
  final _blAwbNoController = TextEditingController();
  final _overrideReasonController = TextEditingController();
  DateTime? _shipmentDate = DateTime.now();
  DateTime? _etd;
  DateTime? _eta;
  bool _overrideQualityGate = false;

  @override
  void dispose() {
    for (final c in [
      _quantityController,
      _cartonsController,
      _grossWeightController,
      _netWeightController,
      _volumeController,
      _portOfLoadingController,
      _portOfDischargeController,
      _shippingLineController,
      _containerNoController,
      _blAwbNoController,
      _overrideReasonController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      showErrorSnack(context, 'Please fix the highlighted fields');
      return;
    }
    final ok = await confirmAction(
      context,
      title: 'Create shipment?',
      message: '${_quantityController.text.trim()} pcs will be booked against this order. '
          'The server checks the final inspection result and that the total never exceeds the order quantity.',
      confirmLabel: 'Create shipment',
    );
    if (!ok) return;
    final draft = ShipmentDraft(
      shipmentDate: toApiDate(_shipmentDate),
      etd: toApiDate(_etd),
      eta: toApiDate(_eta),
      quantityShipped: int.parse(_quantityController.text.trim()),
      cartons: int.tryParse(_cartonsController.text.trim()),
      grossWeight: double.tryParse(_grossWeightController.text.trim()),
      netWeight: double.tryParse(_netWeightController.text.trim()),
      volumeCbm: double.tryParse(_volumeController.text.trim()),
      portOfLoading: blankToNull(_portOfLoadingController.text),
      portOfDischarge: blankToNull(_portOfDischargeController.text),
      shippingLine: blankToNull(_shippingLineController.text),
      containerNo: blankToNull(_containerNoController.text),
      blAwbNo: blankToNull(_blAwbNoController.text),
      overrideQualityGate: _overrideQualityGate,
      overrideReason: _overrideQualityGate ? blankToNull(_overrideReasonController.text) : null,
    );
    ref.read(shipmentFormControllerProvider.notifier).submit(widget.orderId, draft);
  }

  Widget _text(TextEditingController c, String label, bool disabled,
          {String? hint, TextCapitalization caps = TextCapitalization.none}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: TextFormField(
          controller: c,
          enabled: !disabled,
          textInputAction: TextInputAction.next,
          textCapitalization: caps,
          decoration: InputDecoration(labelText: '$label (optional)', hintText: hint),
        ),
      );

  Widget _decimal(TextEditingController c, String label, String suffix, bool disabled) => TextFormField(
        controller: c,
        enabled: !disabled,
        keyboardType: NumberInput.decimalKeyboard,
        inputFormatters: NumberInput.decimal,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: label, suffixText: suffix),
        validator: Validators.money(required: false, what: label),
      );

  @override
  Widget build(BuildContext context) {
    ref.listen(shipmentFormControllerProvider, (previous, next) {
      if (next is ShipmentFormSuccess) {
        showSuccessSnack(context, 'Shipment ${next.shipment.shipmentNo} created');
        Navigator.of(context).pop(next.shipment);
      } else if (next is ShipmentFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(shipmentFormControllerProvider);
    final isSubmitting = formState is ShipmentFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('New Shipment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            SectionHeader('Quantity', icon: Icons.inventory_2_rounded, accentColor: AppModules.shipment.color),
            AppCard(
              accentColor: AppModules.shipment.color,
              child: Column(children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: NumberInput.integer,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Quantity shipped', suffixText: 'pcs'),
                        validator: Validators.positiveInt(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _cartonsController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: NumberInput.integer,
                        decoration: const InputDecoration(labelText: 'Cartons (optional)'),
                        validator: Validators.positiveInt(required: false, what: 'Cartons'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _decimal(_grossWeightController, 'Gross wt', 'kg', isSubmitting)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _decimal(_netWeightController, 'Net wt', 'kg', isSubmitting)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _decimal(_volumeController, 'Volume', 'CBM', isSubmitting)),
                  ],
                ),
              ]),
            ),
            SectionHeader('Dates', icon: Icons.event_rounded, accentColor: AppModules.shipment.color),
            AppCard(
              accentColor: AppModules.shipment.color,
              child: Column(children: [
                DateField(
                  label: 'Shipment date',
                  enabled: !isSubmitting,
                  value: _shipmentDate,
                  onChanged: (d) => setState(() => _shipmentDate = d),
                ),
                const SizedBox(height: AppSpacing.md),
                DateField(
                  label: 'ETD (departure)',
                  enabled: !isSubmitting,
                  value: _etd,
                  onChanged: (d) => setState(() => _etd = d),
                ),
                const SizedBox(height: AppSpacing.md),
                DateField(
                  label: 'ETA (arrival)',
                  enabled: !isSubmitting,
                  value: _eta,
                  firstDate: _etd,
                  validator: (d) =>
                      (d != null && _etd != null && d.isBefore(_etd!)) ? 'ETA cannot be before ETD' : null,
                  onChanged: (d) => setState(() => _eta = d),
                ),
              ]),
            ),
            SectionHeader('Logistics', icon: Icons.route_rounded, accentColor: AppModules.shipment.color),
            AppCard(
              accentColor: AppModules.shipment.color,
              child: Column(children: [
                _text(_portOfLoadingController, 'Port of loading', isSubmitting, caps: TextCapitalization.words),
                _text(_portOfDischargeController, 'Port of discharge', isSubmitting,
                    hint: 'e.g. Hamburg', caps: TextCapitalization.words),
                _text(_shippingLineController, 'Shipping line', isSubmitting,
                    hint: 'e.g. Maersk', caps: TextCapitalization.words),
                _text(_containerNoController, 'Container no.', isSubmitting, caps: TextCapitalization.characters),
                _text(_blAwbNoController, 'B/L or AWB no.', isSubmitting, caps: TextCapitalization.characters),
              ]),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Override quality gate'),
              subtitle: const Text('Ship without a passed final inspection — needs override permission'),
              value: _overrideQualityGate,
              onChanged: isSubmitting ? null : (v) => setState(() => _overrideQualityGate = v),
            ),
            if (_overrideQualityGate)
              TextFormField(
                controller: _overrideReasonController,
                enabled: !isSubmitting,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Override reason'),
                validator: Validators.required('Override reason'),
              ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
                label: 'Create shipment', icon: Icons.check_rounded, loading: isSubmitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
