import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/order_form_controller.dart';
import '../domain/order.dart';

/// Document 7 (#48-49): order creation — itemized style/factory/color/size
/// lines. Doc 9.4's factory-buyer-approval gate is enforced server-side; the
/// override toggle below only matters for a user holding
/// ORDER_OVERRIDE_FACTORY_APPROVAL, and a 400 for anyone else surfaces via
/// Failure/SnackBar same as any other validation error.
class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderItemRow {
  _OrderItemRow()
      : styleIdController = TextEditingController(),
        factoryIdController = TextEditingController(),
        colorController = TextEditingController(),
        sizeController = TextEditingController(),
        quantityController = TextEditingController(),
        unitPriceController = TextEditingController();

  final TextEditingController styleIdController;
  final TextEditingController factoryIdController;
  final TextEditingController colorController;
  final TextEditingController sizeController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  OrderItemDraft toDraft() => OrderItemDraft(
        styleId: int.parse(styleIdController.text.trim()),
        factoryId: int.parse(factoryIdController.text.trim()),
        color: colorController.text.trim().isEmpty ? null : colorController.text.trim(),
        size: sizeController.text.trim().isEmpty ? null : sizeController.text.trim(),
        quantity: int.parse(quantityController.text.trim()),
        unitPrice: double.parse(unitPriceController.text.trim()),
      );

  void dispose() {
    styleIdController.dispose();
    factoryIdController.dispose();
    colorController.dispose();
    sizeController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buyerPoNoController = TextEditingController();
  final _buyerIdController = TextEditingController();
  final _quotationIdController = TextEditingController();
  final _currencyController = TextEditingController();
  final _incotermController = TextEditingController();
  final _destinationController = TextEditingController();
  final _overrideReasonController = TextEditingController();
  DateTime _orderDate = DateTime.now();
  DateTime? _exFactoryDate;
  DateTime? _deliveryDate;
  bool _overrideFactoryApproval = false;
  final List<_OrderItemRow> _items = [_OrderItemRow()];

  @override
  void dispose() {
    _buyerPoNoController.dispose();
    _buyerIdController.dispose();
    _quotationIdController.dispose();
    _currencyController.dispose();
    _incotermController.dispose();
    _destinationController.dispose();
    _overrideReasonController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  String _iso(DateTime d) => d.toIso8601String().split('T').first;

  Future<void> _pickDate(void Function(DateTime) onPicked, DateTime initial) async {
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => onPicked(picked));
  }

  void _addItem() => setState(() => _items.add(_OrderItemRow()));

  void _removeItem(int index) => setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = OrderDraft(
      buyerPoNo: _buyerPoNoController.text.trim(),
      buyerId: int.parse(_buyerIdController.text.trim()),
      quotationId: int.tryParse(_quotationIdController.text.trim()),
      orderDate: _iso(_orderDate),
      exFactoryDate: _exFactoryDate != null ? _iso(_exFactoryDate!) : null,
      deliveryDate: _deliveryDate != null ? _iso(_deliveryDate!) : null,
      incoterm: _incotermController.text.trim().isEmpty ? null : _incotermController.text.trim().toUpperCase(),
      destinationCountry: _destinationController.text.trim().isEmpty ? null : _destinationController.text.trim().toUpperCase(),
      currency: _currencyController.text.trim().toUpperCase(),
      overrideFactoryApproval: _overrideFactoryApproval,
      overrideReason: _overrideReasonController.text.trim().isEmpty ? null : _overrideReasonController.text.trim(),
      items: _items.map((r) => r.toDraft()).toList(),
    );
    ref.read(orderFormControllerProvider.notifier).submit(draft);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(orderFormControllerProvider, (previous, next) {
      if (next is OrderFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is OrderFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(orderFormControllerProvider);
    final isSubmitting = formState is OrderFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _buyerPoNoController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Buyer PO No'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _buyerIdController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Buyer ID'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quotationIdController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quotation ID (optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Order date'),
              subtitle: Text(_iso(_orderDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSubmitting ? null : () => _pickDate((d) => _orderDate = d, _orderDate),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ex-factory date'),
              subtitle: Text(_exFactoryDate != null ? _iso(_exFactoryDate!) : 'Not set (required for T&A generation)'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSubmitting ? null : () => _pickDate((d) => _exFactoryDate = d, _exFactoryDate ?? _orderDate),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Delivery date (optional)'),
              subtitle: Text(_deliveryDate != null ? _iso(_deliveryDate!) : 'Not set'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSubmitting ? null : () => _pickDate((d) => _deliveryDate = d, _deliveryDate ?? _orderDate),
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
                    controller: _incotermController,
                    enabled: !isSubmitting,
                    maxLength: 3,
                    decoration: const InputDecoration(labelText: 'Incoterm (optional)'),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _destinationController,
              enabled: !isSubmitting,
              maxLength: 2,
              decoration: const InputDecoration(labelText: 'Destination country (optional)'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(onPressed: isSubmitting ? null : _addItem, icon: const Icon(Icons.add), label: const Text('Add item')),
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
                            child: TextFormField(
                              controller: row.styleIdController,
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Style ID'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: row.factoryIdController,
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Factory ID'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          IconButton(
                            onPressed: isSubmitting || _items.length == 1 ? null : () => _removeItem(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: row.colorController,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(labelText: 'Color (optional)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: row.sizeController,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(labelText: 'Size (optional)'),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: row.quantityController,
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Quantity'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: row.unitPriceController,
                              enabled: !isSubmitting,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Unit Price'),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Override factory-buyer approval gate'),
              subtitle: const Text('Requires ORDER_OVERRIDE_FACTORY_APPROVAL permission'),
              value: _overrideFactoryApproval,
              onChanged: isSubmitting ? null : (v) => setState(() => _overrideFactoryApproval = v),
            ),
            if (_overrideFactoryApproval)
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
                  : const Text('Create order'),
            ),
          ],
        ),
      ),
    );
  }
}
