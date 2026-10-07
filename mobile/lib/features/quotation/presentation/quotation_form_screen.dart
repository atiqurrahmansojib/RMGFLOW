import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../costing/data/costing_repository_impl.dart';
import '../application/quotation_form_controller.dart';
import '../domain/quotation.dart';

/// Document 7 (#41): single form for create/revise — revise always produces
/// a new version row referencing the source (Doc 9.2), never mutates it.
/// Picking the approved costing pre-fills style, buyer, quantity and currency.
class QuotationFormScreen extends ConsumerStatefulWidget {
  const QuotationFormScreen({super.key, this.existingQuotation, this.isRevise = false});

  final Quotation? existingQuotation;
  final bool isRevise;

  @override
  ConsumerState<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends ConsumerState<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quotationNoController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _incotermController;
  late final TextEditingController _leadTimeController;
  int? _costingId;
  int? _buyerId;
  int? _styleId;
  DateTime? _validityDate;
  bool _prefilling = false;

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuotation;
    _costingId = q?.costingId;
    _buyerId = q?.buyerId;
    _styleId = q?.styleId;
    // New offers default to a 30-day validity.
    _validityDate = q == null ? DateTime.now().add(const Duration(days: 30)) : parseApiDate(q.validityDate);
    _quotationNoController = TextEditingController(text: q?.quotationNo);
    _quantityController = TextEditingController(text: q?.quantity.toString());
    _unitPriceController = TextEditingController(text: q?.unitPrice.toString());
    _currencyController = TextEditingController(text: q?.currency ?? 'USD');
    _incotermController = TextEditingController(text: q?.incoterm ?? 'FOB');
    _leadTimeController = TextEditingController(text: q?.leadTimeDays?.toString());
  }

  @override
  void dispose() {
    _quotationNoController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _currencyController.dispose();
    _incotermController.dispose();
    _leadTimeController.dispose();
    super.dispose();
  }

  /// Copies style/quantity/currency (and the style's buyer) from the picked costing.
  Future<void> _onCostingPicked(int? id) async {
    setState(() => _costingId = id);
    if (id == null) return;
    setState(() => _prefilling = true);
    try {
      final costing = await ref
          .read(authControllerProvider.notifier)
          .callAuthorized(() => ref.read(costingRepositoryProvider).get(id));
      final styles = await ref.read(styleLookupProvider(null).future);
      if (!mounted) return;
      int? buyerId;
      for (final s in styles) {
        if (s.id == costing.styleId) buyerId = s.parentId;
      }
      setState(() {
        _styleId = costing.styleId;
        _buyerId = buyerId ?? _buyerId;
        _quantityController.text = costing.quantity.toString();
        _currencyController.text = costing.currency;
        if (_unitPriceController.text.isEmpty && costing.targetPrice != null) {
          _unitPriceController.text = costing.targetPrice!.toString();
        }
      });
    } on DioException {
      // Pre-fill is a convenience; the user can still fill the fields by hand.
    } finally {
      if (mounted) setState(() => _prefilling = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = QuotationDraft(
      costingId: _costingId!,
      quotationNo: blankToNull(_quotationNoController.text),
      buyerId: _buyerId!,
      styleId: _styleId!,
      quantity: int.parse(_quantityController.text.trim()),
      unitPrice: double.parse(_unitPriceController.text.trim()),
      currency: _currencyController.text.trim().toUpperCase(),
      incoterm: blankToNull(_incotermController.text)?.toUpperCase(),
      paymentTermsId: widget.existingQuotation?.paymentTermsId,
      validityDate: toApiDate(_validityDate),
      leadTimeDays: int.tryParse(_leadTimeController.text.trim()),
    );
    ref.read(quotationFormControllerProvider.notifier).submit(
          draft: draft,
          reviseId: widget.isRevise ? widget.existingQuotation?.id : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(quotationFormControllerProvider, (previous, next) {
      if (next is QuotationFormSuccess) {
        showSuccessSnack(context, widget.isRevise ? 'New quotation version created' : 'Quotation created');
        Navigator.of(context).pop(next.quotation);
      } else if (next is QuotationFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(quotationFormControllerProvider);
    final isSubmitting = formState is QuotationFormSubmitting;
    const module = AppModules.quotation;
    if (widget.existingQuotation == null) {
      autoSelectSingle(ref, costingLookupProvider(true), current: _costingId, apply: (id) {
        if (mounted && _costingId == null) _onCostingPicked(id);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.isRevise ? 'Revise Quotation' : 'New Quotation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            FormSection(
              title: 'Source',
              subtitle: 'Picking the costing fills style, buyer, quantity and currency',
              icon: AppModules.costing.icon,
              color: module.color,
              children: [
                LookupField(
                  label: 'Approved costing',
                  icon: Icons.calculate_outlined,
                  required: true,
                  enabled: !isSubmitting,
                  initialValue: _costingId,
                  options: costingLookupProvider(true),
                  helperText: 'Only approved costings can be quoted',
                  emptyMessage: 'No approved costings yet. Submit a costing and get it approved first.',
                  onChanged: _onCostingPicked,
                ),
                if (_prefilling) const LinearProgressIndicator(),
                TextFormField(
                  controller: _quotationNoController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(labelText: 'Quotation no. (optional)', hintText: 'e.g. QT-2026-001'),
                ),
                LookupField(
                  label: 'Buyer',
                  icon: Icons.storefront_rounded,
                  required: true,
                  enabled: !isSubmitting,
                  initialValue: _buyerId,
                  options: buyerLookupProvider,
                  onChanged: (v) => setState(() => _buyerId = v),
                ),
                LookupField(
                  label: 'Style',
                  icon: Icons.checkroom_rounded,
                  required: true,
                  enabled: !isSubmitting,
                  initialValue: _styleId,
                  options: styleLookupProvider(_buyerId),
                  emptyMessage: 'This buyer has no styles yet.',
                  onChanged: (v) => setState(() => _styleId = v),
                ),
              ],
            ),
            FormSection(
              title: 'Price',
              icon: Icons.sell_outlined,
              color: module.color,
              children: [
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
                        controller: _unitPriceController,
                        enabled: !isSubmitting,
                        keyboardType: NumberInput.decimalKeyboard,
                        inputFormatters: NumberInput.decimal,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Unit price', helperText: 'Per piece'),
                        validator: Validators.money(what: 'Unit price'),
                      ),
                    ),
                  ],
                ),
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
                      child: CodePickerField(
                        controller: _incotermController,
                        label: 'Incoterm',
                        codes: incotermCodesProvider,
                        required: false,
                        enabled: !isSubmitting,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            FormSection(
              title: 'Terms',
              icon: Icons.event_available_outlined,
              color: module.color,
              children: [
                TextFormField(
                  controller: _leadTimeController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: NumberInput.integer,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Lead time (optional)', suffixText: 'days'),
                  validator: Validators.positiveInt(required: false, what: 'Lead time'),
                ),
                DateField(
                  label: 'Valid until',
                  value: _validityDate,
                  enabled: !isSubmitting,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  onChanged: (d) => setState(() => _validityDate = d),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: widget.isRevise ? 'Create new version' : 'Create quotation',
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
