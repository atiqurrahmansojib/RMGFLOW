import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/quotation_form_controller.dart';
import '../domain/quotation.dart';

/// Document 7 (#41): single form for create/revise — revise always produces
/// a new version row referencing the source (Doc 9.2), never mutates it.
class QuotationFormScreen extends ConsumerStatefulWidget {
  const QuotationFormScreen({super.key, this.existingQuotation, this.isRevise = false});

  final Quotation? existingQuotation;
  final bool isRevise;

  @override
  ConsumerState<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends ConsumerState<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _costingIdController;
  late final TextEditingController _quotationNoController;
  late final TextEditingController _buyerIdController;
  late final TextEditingController _styleIdController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _incotermController;
  late final TextEditingController _leadTimeController;

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuotation;
    _costingIdController = TextEditingController(text: q?.costingId.toString());
    _quotationNoController = TextEditingController(text: q?.quotationNo);
    _buyerIdController = TextEditingController(text: q?.buyerId.toString());
    _styleIdController = TextEditingController(text: q?.styleId.toString());
    _quantityController = TextEditingController(text: q?.quantity.toString());
    _unitPriceController = TextEditingController(text: q?.unitPrice.toString());
    _currencyController = TextEditingController(text: q?.currency);
    _incotermController = TextEditingController(text: q?.incoterm);
    _leadTimeController = TextEditingController(text: q?.leadTimeDays?.toString());
  }

  @override
  void dispose() {
    _costingIdController.dispose();
    _quotationNoController.dispose();
    _buyerIdController.dispose();
    _styleIdController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _currencyController.dispose();
    _incotermController.dispose();
    _leadTimeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = QuotationDraft(
      costingId: int.parse(_costingIdController.text.trim()),
      quotationNo: _quotationNoController.text.trim().isEmpty ? null : _quotationNoController.text.trim(),
      buyerId: int.parse(_buyerIdController.text.trim()),
      styleId: int.parse(_styleIdController.text.trim()),
      quantity: int.parse(_quantityController.text.trim()),
      unitPrice: double.parse(_unitPriceController.text.trim()),
      currency: _currencyController.text.trim().toUpperCase(),
      incoterm: _incotermController.text.trim().isEmpty ? null : _incotermController.text.trim().toUpperCase(),
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
        Navigator.of(context).pop();
      } else if (next is QuotationFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(quotationFormControllerProvider);
    final isSubmitting = formState is QuotationFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isRevise ? 'Revise Quotation' : 'New Quotation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _costingIdController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Approved Costing ID'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quotationNoController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Quotation No (optional)'),
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
                    controller: _styleIdController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Style ID'),
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
                    controller: _unitPriceController,
                    enabled: !isSubmitting,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Unit Price'),
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
              controller: _leadTimeController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Lead time (days, optional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.isRevise ? 'Create new version' : 'Create quotation'),
            ),
          ],
        ),
      ),
    );
  }
}
