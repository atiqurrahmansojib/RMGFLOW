import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
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
    this.sourceItemId,
    this.unitCostHidden = false,
  })  : componentType = componentType ?? CostingComponentType.fabric,
        descriptionController = TextEditingController(text: description),
        unitCostController = TextEditingController(text: unitCost?.toString()),
        consumptionController = TextEditingController(text: consumption?.toString()),
        wastagePercentController = TextEditingController(text: (wastagePercent ?? 0).toString());

  CostingComponentType componentType;

  /// Line of the costing being edited/revised this row continues (server carry-over key).
  final int? sourceItemId;

  /// True when the server masked this line's unit cost (no COSTING_VIEW_MARGIN):
  /// leaving the field blank keeps the hidden value instead of wiping it.
  final bool unitCostHidden;
  final TextEditingController descriptionController;
  final TextEditingController unitCostController;
  final TextEditingController consumptionController;
  final TextEditingController wastagePercentController;

  CostingItemDraft toDraft() => CostingItemDraft(
        componentType: componentType,
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        unitCost: double.tryParse(unitCostController.text.trim()) ?? (unitCostHidden ? null : 0),
        sourceItemId: sourceItemId,
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
  int? _styleId;
  int? _inquiryId;
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
    _styleId = costing?.styleId ?? widget.initialStyleId;
    _inquiryId = costing?.inquiryId;
    _currencyController = TextEditingController(text: costing?.currency ?? 'USD');
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
            sourceItemId: i.id,
            unitCostHidden: i.unitCost == null,
          )));
    }
    if (_items.isEmpty) _items.add(_CostingItemRow());
  }

  @override
  void dispose() {
    _currencyController.dispose();
    _exchangeRateController.dispose();
    _quantityController.dispose();
    _targetPriceController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  /// New rows default to the next component not on the sheet yet
  /// (fabric → knitting → dyeing …), so a typical sheet needs no dropdown taps.
  void _addItem() {
    final used = _items.map((r) => r.componentType).toSet();
    final next = CostingComponentType.values
        .firstWhere((t) => !used.contains(t), orElse: () => CostingComponentType.values.last);
    setState(() => _items.add(_CostingItemRow(componentType: next)));
  }

  Future<void> _removeItem(int index) async {
    final row = _items[index];
    final hasData = row.unitCostController.text.isNotEmpty || row.consumptionController.text.isNotEmpty;
    if (hasData) {
      final ok = await confirmAction(
        context,
        title: 'Remove this cost item?',
        message: '${row.componentType.label} line will be removed from the costing.',
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      showErrorSnack(context, 'Add at least one cost item');
      return;
    }
    final draft = CostingDraft(
      styleId: _styleId!,
      inquiryId: _inquiryId,
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
        showSuccessSnack(context, _isRevise ? 'New costing version created' : 'Costing saved');
        Navigator.of(context).pop(next.costing);
      } else if (next is CostingFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(costingFormControllerProvider);
    final isSubmitting = formState is CostingFormSubmitting;
    final title = _isRevise ? 'Revise Costing' : (_isEditDraft ? 'Edit Costing Draft' : 'New Costing');
    const module = AppModules.costing;
    if (!_isEditDraft) {
      autoSelectSingle(ref, styleLookupProvider(null), current: _styleId, apply: (id) {
        if (mounted && _styleId == null) setState(() => _styleId = id);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            FormSection(
              title: 'What is being costed',
              icon: Icons.checkroom_rounded,
              color: module.color,
              children: [
                LookupField(
                  label: 'Style',
                  icon: Icons.checkroom_rounded,
                  required: true,
                  enabled: !isSubmitting && !_isEditDraft,
                  initialValue: _styleId,
                  options: styleLookupProvider(null),
                  emptyMessage: 'No styles yet. Add a style first from the Styles screen.',
                  onChanged: (v) => _styleId = v,
                ),
                LookupField(
                  label: 'Inquiry',
                  icon: Icons.mail_outline_rounded,
                  enabled: !isSubmitting,
                  initialValue: _inquiryId,
                  options: inquiryLookupProvider,
                  helperText: 'Link the buyer inquiry this costing answers',
                  onChanged: (v) => _inquiryId = v,
                ),
              ],
            ),
            FormSection(
              title: 'Commercials',
              icon: Icons.payments_outlined,
              color: module.color,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CodePickerField(
                        controller: _currencyController,
                        label: 'Currency',
                        codes: currencyCodesProvider,
                        enabled: !isSubmitting,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _exchangeRateController,
                        enabled: !isSubmitting,
                        keyboardType: NumberInput.decimalKeyboard,
                        inputFormatters: NumberInput.decimal,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Exchange rate', helperText: 'To base currency'),
                        validator: Validators.money(what: 'Exchange rate'),
                      ),
                    ),
                  ],
                ),
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
                        decoration: const InputDecoration(labelText: 'Quantity', suffixText: 'pcs'),
                        validator: Validators.positiveInt(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _targetPriceController,
                        enabled: !isSubmitting,
                        keyboardType: NumberInput.decimalKeyboard,
                        inputFormatters: NumberInput.decimal,
                        textInputAction: TextInputAction.next,
                        decoration:
                            const InputDecoration(labelText: 'Target price (optional)', helperText: 'Per piece'),
                        validator: Validators.money(required: false, what: 'Target price'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SectionHeader(
              'Cost items',
              count: _items.length,
              icon: Icons.list_alt_rounded,
              accentColor: module.color,
              actionLabel: 'Add item',
              onAction: isSubmitting ? null : _addItem,
            ),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              final isLast = index == _items.length - 1;
              return AppCard(
                key: ObjectKey(row),
                accentColor: module.color,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<CostingComponentType>(
                            initialValue: row.componentType,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: 'Component ${index + 1}'),
                            items: CostingComponentType.values
                                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                                .toList(),
                            onChanged: isSubmitting ? null : (v) => setState(() => row.componentType = v!),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove item',
                          onPressed: isSubmitting || _items.length == 1 ? null : () => _removeItem(index),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: row.descriptionController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Description (optional)'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: row.unitCostController,
                            enabled: !isSubmitting,
                            keyboardType: NumberInput.decimalKeyboard,
                            inputFormatters: NumberInput.decimal,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Unit cost',
                              hintText: row.unitCostHidden ? 'Kept' : null,
                              helperText: row.unitCostHidden ? 'Hidden · blank keeps it' : null,
                            ),
                            validator:
                                Validators.money(required: !row.unitCostHidden, allowZero: true, what: 'Unit cost'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: row.consumptionController,
                            enabled: !isSubmitting,
                            keyboardType: NumberInput.decimalKeyboard,
                            inputFormatters: NumberInput.decimal,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'Consumption'),
                            validator: Validators.money(what: 'Consumption'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: row.wastagePercentController,
                            enabled: !isSubmitting,
                            keyboardType: NumberInput.decimalKeyboard,
                            inputFormatters: NumberInput.decimal,
                            textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
                            onFieldSubmitted: isLast ? (_) => _submit() : null,
                            decoration: const InputDecoration(labelText: 'Wastage %'),
                            validator: Validators.percent(what: 'Wastage'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isSubmitting ? null : _addItem,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add another cost item'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Totals and margin are calculated by the server when you save.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: _isRevise ? 'Create new version' : (_isEditDraft ? 'Save changes' : 'Create costing'),
              icon: Icons.check_rounded,
              loading: isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
