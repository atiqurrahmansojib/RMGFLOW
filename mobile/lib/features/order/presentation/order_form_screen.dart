import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/widgets.dart';
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
      : colorController = TextEditingController(),
        sizeController = TextEditingController(),
        quantityController = TextEditingController(),
        unitPriceController = TextEditingController();

  int? styleId;
  int? factoryId;
  final TextEditingController colorController;
  final TextEditingController sizeController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  double get lineValue =>
      (int.tryParse(quantityController.text.trim()) ?? 0) * (double.tryParse(unitPriceController.text.trim()) ?? 0);

  OrderItemDraft toDraft() => OrderItemDraft(
        styleId: styleId!,
        factoryId: factoryId!,
        color: blankToNull(colorController.text),
        size: blankToNull(sizeController.text),
        quantity: int.parse(quantityController.text.trim()),
        unitPrice: double.parse(unitPriceController.text.trim()),
      );

  void dispose() {
    colorController.dispose();
    sizeController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buyerPoNoController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD');
  final _incotermController = TextEditingController(text: 'FOB');
  final _destinationController = TextEditingController();
  final _overrideReasonController = TextEditingController();
  int? _buyerId;
  int? _quotationId;
  DateTime _orderDate = DateTime.now();
  DateTime? _exFactoryDate;
  DateTime? _deliveryDate;
  bool _overrideFactoryApproval = false;
  final List<_OrderItemRow> _items = [_OrderItemRow()];

  @override
  void dispose() {
    _buyerPoNoController.dispose();
    _currencyController.dispose();
    _incotermController.dispose();
    _destinationController.dispose();
    _overrideReasonController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_OrderItemRow()));

  Future<void> _removeItem(int index) async {
    final row = _items[index];
    if (row.styleId != null || row.quantityController.text.isNotEmpty) {
      final ok = await confirmAction(
        context,
        title: 'Remove item ${index + 1}?',
        message: 'This order line will be removed.',
        confirmLabel: 'Remove',
        destructive: true,
      );
      if (!ok) return;
    }
    setState(() {
      _items.removeAt(index);
      row.dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      showErrorSnack(context, 'Please fix the highlighted fields');
      return;
    }
    final total = _items.fold<double>(0, (sum, r) => sum + r.lineValue);
    final qty = _items.fold<int>(0, (sum, r) => sum + (int.tryParse(r.quantityController.text.trim()) ?? 0));
    final ok = await confirmAction(
      context,
      title: 'Create this order?',
      message: 'PO ${_buyerPoNoController.text.trim()} · ${_items.length} line(s) · $qty pcs · '
          '${_currencyController.text.trim().toUpperCase()} ${total.toStringAsFixed(2)}.\n\n'
          'Once confirmed, changes need an amendment.',
      confirmLabel: 'Create order',
    );
    if (!ok) return;
    final draft = OrderDraft(
      buyerPoNo: _buyerPoNoController.text.trim(),
      buyerId: _buyerId!,
      quotationId: _quotationId,
      orderDate: toApiDate(_orderDate)!,
      exFactoryDate: toApiDate(_exFactoryDate),
      deliveryDate: toApiDate(_deliveryDate),
      incoterm: blankToNull(_incotermController.text)?.toUpperCase(),
      destinationCountry: blankToNull(_destinationController.text)?.toUpperCase(),
      currency: _currencyController.text.trim().toUpperCase(),
      overrideFactoryApproval: _overrideFactoryApproval,
      overrideReason: _overrideFactoryApproval ? blankToNull(_overrideReasonController.text) : null,
      items: _items.map((r) => r.toDraft()).toList(),
    );
    ref.read(orderFormControllerProvider.notifier).submit(draft);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(orderFormControllerProvider, (previous, next) {
      if (next is OrderFormSuccess) {
        showSuccessSnack(context, 'Order ${next.order.orderNo} created');
        // The list opens the new order's hub straight away.
        Navigator.of(context).pop(next.order);
      } else if (next is OrderFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(orderFormControllerProvider);
    final isSubmitting = formState is OrderFormSubmitting;
    final total = _items.fold<double>(0, (sum, r) => sum + r.lineValue);

    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            SectionHeader('Order details', icon: Icons.receipt_long_rounded, accentColor: AppModules.orders.color),
            AppCard(
              accentColor: AppModules.orders.color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _buyerPoNoController,
                    enabled: !isSubmitting,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    decoration:
                        const InputDecoration(labelText: 'Buyer PO number', hintText: "As printed on the buyer's PO"),
                    validator: Validators.required('Buyer PO number'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LookupField(
                    label: 'Buyer',
                    icon: Icons.storefront_rounded,
                    required: true,
                    enabled: !isSubmitting,
                    initialValue: _buyerId,
                    options: buyerLookupProvider,
                    onChanged: (v) => setState(() {
                      if (v != _buyerId) {
                        _quotationId = null;
                        // Styles are buyer-specific; a buyer switch invalidates picked styles.
                        for (final r in _items) {
                          r.styleId = null;
                        }
                      }
                      _buyerId = v;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LookupField(
                    key: ValueKey('quotation-$_buyerId'),
                    label: 'Quotation',
                    icon: Icons.request_quote_outlined,
                    enabled: !isSubmitting && _buyerId != null,
                    initialValue: _quotationId,
                    options: quotationLookupProvider(_buyerId),
                    helperText: _buyerId == null ? 'Pick the buyer first' : 'Link the accepted quotation, if any',
                    emptyMessage: 'No quotations for this buyer.',
                    onChanged: (v) => setState(() => _quotationId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DateField(
                    label: 'Order date',
                    required: true,
                    enabled: !isSubmitting,
                    value: _orderDate,
                    onChanged: (d) => setState(() => _orderDate = d ?? _orderDate),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DateField(
                    label: 'Ex-factory date',
                    enabled: !isSubmitting,
                    value: _exFactoryDate,
                    firstDate: _orderDate,
                    helperText: 'Needed to generate the T&A calendar',
                    onChanged: (d) => setState(() => _exFactoryDate = d),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DateField(
                    label: 'Delivery date',
                    enabled: !isSubmitting,
                    value: _deliveryDate,
                    firstDate: _exFactoryDate ?? _orderDate,
                    validator: (d) => (d != null && _exFactoryDate != null && d.isBefore(_exFactoryDate!))
                        ? 'Delivery cannot be before ex-factory'
                        : null,
                    onChanged: (d) => setState(() => _deliveryDate = d),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CodePickerField(
                          controller: _currencyController,
                          label: 'Currency',
                          codes: currencyCodesProvider,
                          enabled: !isSubmitting,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _incotermController,
                          enabled: !isSubmitting,
                          maxLength: 3,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'Incoterm (optional)', counterText: ''),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _destinationController,
                          enabled: !isSubmitting,
                          maxLength: 2,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'Destination', hintText: 'US', counterText: ''),
                          validator: (v) =>
                              (v != null && v.trim().isNotEmpty && v.trim().length != 2) ? '2 letters' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SectionHeader(
              'Order lines',
              icon: Icons.checkroom_rounded,
              accentColor: AppModules.styles.color,
              count: _items.length,
              actionLabel: 'Add line',
              onAction: isSubmitting ? null : _addItem,
            ),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return AppCard(
                key: ObjectKey(row),
                accentColor: AppModules.styles.color,
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Line ${index + 1}', style: Theme.of(context).textTheme.titleSmall)),
                          IconButton(
                            tooltip: 'Remove line',
                            onPressed: isSubmitting || _items.length == 1 ? null : () => _removeItem(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      LookupField(
                        key: ValueKey('style-$index-$_buyerId'),
                        label: 'Style',
                        icon: Icons.checkroom_rounded,
                        required: true,
                        enabled: !isSubmitting,
                        initialValue: row.styleId,
                        options: styleLookupProvider(_buyerId),
                        emptyMessage: _buyerId == null ? 'No styles yet.' : 'This buyer has no styles yet.',
                        onChanged: (v) => row.styleId = v,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LookupField(
                        label: 'Factory',
                        icon: Icons.factory_outlined,
                        required: true,
                        enabled: !isSubmitting,
                        initialValue: row.factoryId,
                        options: factoryLookupProvider,
                        onChanged: (v) => row.factoryId = v,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: row.colorController,
                              enabled: !isSubmitting,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(labelText: 'Color (optional)'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextFormField(
                              controller: row.sizeController,
                              enabled: !isSubmitting,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(labelText: 'Size (optional)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: row.quantityController,
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.number,
                              inputFormatters: NumberInput.integer,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(labelText: 'Quantity', suffixText: 'pcs'),
                              validator: Validators.positiveInt(),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextFormField(
                              controller: row.unitPriceController,
                              enabled: !isSubmitting,
                              keyboardType: NumberInput.decimalKeyboard,
                              inputFormatters: NumberInput.decimal,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(labelText: 'Unit price'),
                              validator: Validators.money(what: 'Unit price'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            AppCard(
              accentColor: AppModules.financial.color,
              child: InfoRow(
                label: 'Estimated order value',
                value: '${_currencyController.text.trim().toUpperCase()} ${total.toStringAsFixed(2)}',
                emphasize: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Override factory approval check'),
              subtitle:
                  const Text('Only for users allowed to place orders at a factory not yet approved by this buyer'),
              value: _overrideFactoryApproval,
              onChanged: isSubmitting ? null : (v) => setState(() => _overrideFactoryApproval = v),
            ),
            if (_overrideFactoryApproval)
              TextFormField(
                controller: _overrideReasonController,
                enabled: !isSubmitting,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Override reason'),
                validator: Validators.required('Override reason'),
              ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Create order', icon: Icons.check_rounded, loading: isSubmitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
