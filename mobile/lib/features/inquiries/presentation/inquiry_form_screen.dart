import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/inquiry_form_controller.dart';
import '../domain/inquiry.dart';

/// Document 7 (#26-27): single form for create/edit, plus a status-change action
/// for existing inquiries (Doc 10.1 state machine — the backend enforces which
/// transitions are legal; this UI just offers the full enum and lets a 400 surface
/// via the Failure/SnackBar path if the user picks an invalid one).
class InquiryFormScreen extends ConsumerStatefulWidget {
  const InquiryFormScreen({super.key, this.existingInquiry});

  final Inquiry? existingInquiry;

  @override
  ConsumerState<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends ConsumerState<InquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _inquiryNoController;
  late final TextEditingController _buyerIdController;
  late final TextEditingController _targetQuantityController;
  late final TextEditingController _targetPriceController;
  late final TextEditingController _targetCurrencyController;

  bool get _isEdit => widget.existingInquiry != null;

  @override
  void initState() {
    super.initState();
    final inquiry = widget.existingInquiry;
    _inquiryNoController = TextEditingController(text: inquiry?.inquiryNo);
    _buyerIdController = TextEditingController(text: inquiry?.buyerId.toString());
    _targetQuantityController = TextEditingController(text: inquiry?.targetQuantity?.toString());
    _targetPriceController = TextEditingController(text: inquiry?.targetPrice?.toString());
    _targetCurrencyController = TextEditingController(text: inquiry?.targetCurrency);
  }

  @override
  void dispose() {
    _inquiryNoController.dispose();
    _buyerIdController.dispose();
    _targetQuantityController.dispose();
    _targetPriceController.dispose();
    _targetCurrencyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = InquiryDraft(
      inquiryNo: _inquiryNoController.text.trim(),
      buyerId: int.parse(_buyerIdController.text.trim()),
      targetQuantity: int.tryParse(_targetQuantityController.text.trim()),
      targetPrice: double.tryParse(_targetPriceController.text.trim()),
      targetCurrency: _targetCurrencyController.text.trim().isEmpty ? null : _targetCurrencyController.text.trim().toUpperCase(),
    );
    ref.read(inquiryFormControllerProvider.notifier).submit(draft: draft, existingId: widget.existingInquiry?.id);
  }

  Future<void> _showStatusDialog() async {
    final inquiry = widget.existingInquiry!;
    final status = await showDialog<InquiryStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Change status'),
        children: InquiryStatus.values
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(s),
                  child: Text(s.label),
                ))
            .toList(),
      ),
    );
    if (status == null || !mounted) return;

    String? lostReason;
    if (status == InquiryStatus.lost) {
      final controller = TextEditingController();
      lostReason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reason for loss'),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Confirm')),
          ],
        ),
      );
      if (lostReason == null || lostReason.isEmpty) return;
    }

    ref.read(inquiryFormControllerProvider.notifier).changeStatus(inquiry.id, status, lostReason: lostReason);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(inquiryFormControllerProvider, (previous, next) {
      if (next is InquiryFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is InquiryFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(inquiryFormControllerProvider);
    final isSubmitting = formState is InquiryFormSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Inquiry' : 'New Inquiry'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.sync_alt),
              tooltip: 'Change status',
              onPressed: isSubmitting ? null : _showStatusDialog,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isEdit)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Status: ${widget.existingInquiry!.status.label}', style: Theme.of(context).textTheme.titleMedium),
              ),
            TextFormField(
              controller: _inquiryNoController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Inquiry Number'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _buyerIdController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Buyer ID'),
              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter a valid buyer id' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetQuantityController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target quantity (optional)'),
            ),
            TextFormField(
              controller: _targetPriceController,
              enabled: !isSubmitting,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Target price (optional)'),
            ),
            TextFormField(
              controller: _targetCurrencyController,
              enabled: !isSubmitting,
              maxLength: 3,
              decoration: const InputDecoration(labelText: 'Currency (e.g. USD)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Save changes' : 'Create inquiry'),
            ),
          ],
        ),
      ),
    );
  }
}
