import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/costing_form_controller.dart';
import '../domain/costing.dart';

/// Document 7 (#38): itemized cost entry — one row per cost component.
/// Document 9.1: total_cost/margin are NEVER computed here; the server
/// recalculates on every save and this screen only ever shows what comes
/// back from `Costing.totalCost`/`marginPercent` after a successful submit.
class CostingFormScreen extends ConsumerStatefulWidget {
  const CostingFormScreen({
    super.key,
    this.existingCosting,
    this.initialStyleId,
    this.mode = CostingFormMode.create,
  });

  final Costing? existingCosting;
  final int? initialStyleId;
  final CostingFormMode mode;

  @override
  ConsumerState<CostingFormScreen> createState() => _CostingFormScreenState();
}

class _CostingItemRow {
  _CostingItemRow({
    CostingComponentType? componentType,
    String? description,
    double? unitCost,
    double? consumption,
    double? wastagePercent,
  })  : componentType = componentType ?? CostingComponentType.fabric,
        descriptionController = TextEditingController(text: description),
        unitCostController = TextEditingController(text: unitCost?.toString()),
        consumptionController = TextEditingController(text: consumption?.toString()),
        wastagePercentController = TextEditingController(text: (wastagePercent ?? 0).toString());

  CostingComponentType componentType;
  final TextEditingController descriptionController;
  final TextEditingController unitCostController;
  final TextEditingController consumptionController;
  final TextEditingController wastagePercentController;

  CostingItemDraft toDraft() => CostingItemDraft(
        componentType: componentType,
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        unitCost: double.tryParse(unitCostController.text.trim()) ?? 0,
        consumption: double.tryParse(consumptionController.text.trim()) ?? 0,
        wastagePercent: double.tryParse(wastagePercentController.text.trim()) ?? 0,
      );

  void dispose() {
    descriptionController.dispose();
    unitCostController.dispose();
    consumptionController.dispose();
    wastagePercentController.dispose();
  }
}

class _CostingFormScreenState extends ConsumerState<CostingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _styleIdController;
  late final TextEditingController _inquiryIdController;
  late final TextEditingController _currencyController;
  late final TextEditingController _exchangeRateController;
  late final TextEditingController _quantityController;
  late final TextEditingController _targetPriceController;
  final List<_CostingItemRow> _items = [];

  bool get _isRevise => widget.mode == CostingFormMode.revise;
  bool get _isEditDraft => widget.mode == CostingFormMode.editDraft;

  @override
  void initState() {
    super.initState();
    final costing = widget.existingCosting;
    _styleIdController = TextEditingController(text: costing?.styleId.toString() ?? widget.initialStyleId?.toString());
    _inquiryIdController = TextEditingController(text: costing?.inquiryId?.toString());
    _currencyController = TextEditingController(text: costing?.currency);
    _exchangeRateController = TextEditingController(text: costing?.exchangeRate.toString() ?? '1');
    _quantityController = TextEditingController(text: costing?.quantity.toString());
    _targetPriceController = TextEditingController(text: costing?.targetPrice?.toString());
    if (costing != null) {
      _items.addAll(costing.items.map((i) => _CostingItemRow(
            componentType: i.componentType,
            description: i.description,
            unitCost: i.unitCost,
            consumption: i.consumption,
            wastagePercent: i.wastagePercent,
          )));
    }
    if (_items.isEmpty) _items.add(_CostingItemRow());
  }

  @override
  void dispose() {
    _styleIdController.dispose();
    _inquiryIdController.dispose();
    _currencyController.dispose();
    _exchangeRateController.dispose();
    _quantityController.dispose();
    _targetPriceController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_CostingItemRow()));

  void _removeItem(int index) => setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one cost item')));
      return;
    }
    final draft = CostingDraft(
      styleId: int.parse(_styleIdController.text.trim()),
      inquiryId: int.tryParse(_inquiryIdController.text.trim()),
      currency: _currencyController.text.trim().toUpperCase(),
      exchangeRate: double.parse(_exchangeRateController.text.trim()),
      quantity: int.parse(_quantityController.text.trim()),
      targetPrice: double.tryParse(_targetPriceController.text.trim()),
      items: _items.map((r) => r.toDraft()).toList(),
    );
    ref.read(costingFormControllerProvider.notifier).submit(
          draft: draft,
          mode: widget.mode,
          existingId: widget.existingCosting?.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(costingFormControllerProvider, (previous, next) {
      if (next is CostingFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is CostingFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(costingFormControllerProvider);
    final isSubmitting = formState is CostingFormSubmitting;
    final title = _isRevise ? 'Revise Costing' : (_isEditDraft ? 'Edit Costing Draft' : 'New Costing');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _styleIdController,
              enabled: !isSubmitting && !_isEditDraft,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Style ID'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _inquiryIdController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Inquiry ID (optional)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _currencyController,
                    enabled: !isSubmitting,
                    maxLength: 3,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _exchangeRateController,
                    enabled: !isSubmitting,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Exchange Rate'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _targetPriceController,
                    enabled: !isSubmitting,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Target Price (optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cost Items', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: isSubmitting ? null : _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ],
            ),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<CostingComponentType>(
                              value: row.componentType,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Component'),
                              items: CostingComponentType.values
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                                  .toList(),
                              onChanged: isSubmitting ? null : (v) => setState(() => row.componentType = v!),
                            ),
                          ),
                          IconButton(
                            onPressed: isSubmitting ? null : () => _removeItem(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: row.descriptionController,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(labelText: 'Description (optional)'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: row.unitCostController,
                              enabled: !isSubmitting,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Unit cost'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: row.consumptionController,
                              enabled: !isSubmitting,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Consumption'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: row.wastagePercentController,
                              enabled: !isSubmitting,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Wastage %'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isRevise ? 'Create new version' : (_isEditDraft ? 'Save changes' : 'Create costing')),
            ),
          ],
        ),
      ),
    );
  }
}
