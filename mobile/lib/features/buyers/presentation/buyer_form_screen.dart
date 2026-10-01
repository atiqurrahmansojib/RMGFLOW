import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/buyer_form_controller.dart';
import '../domain/buyer.dart';

/// Document 7 (#18): single form for create AND edit. Doc 8.12/9's optimistic
/// locking means an edit always round-trips the `version` it was loaded with —
/// a 409 here means someone else changed this buyer first (Doc 11.3).
class BuyerFormScreen extends ConsumerStatefulWidget {
  const BuyerFormScreen({super.key, this.existingBuyer});

  final Buyer? existingBuyer;

  @override
  ConsumerState<BuyerFormScreen> createState() => _BuyerFormScreenState();
}

class _BuyerFormScreenState extends ConsumerState<BuyerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _groupController;
  late final TextEditingController _countryController;
  late final TextEditingController _currencyController;
  late final TextEditingController _incotermController;

  bool get _isEdit => widget.existingBuyer != null;

  @override
  void initState() {
    super.initState();
    final buyer = widget.existingBuyer;
    _codeController = TextEditingController(text: buyer?.code);
    _nameController = TextEditingController(text: buyer?.name);
    _groupController = TextEditingController(text: buyer?.groupName);
    _countryController = TextEditingController(text: buyer?.country);
    _currencyController = TextEditingController(text: buyer?.defaultCurrency);
    _incotermController = TextEditingController(text: buyer?.defaultIncoterm);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _groupController.dispose();
    _countryController.dispose();
    _currencyController.dispose();
    _incotermController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = BuyerDraft(
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      groupName: _groupController.text.trim().isEmpty ? null : _groupController.text.trim(),
      country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim().toUpperCase(),
      defaultCurrency: _currencyController.text.trim().isEmpty ? null : _currencyController.text.trim().toUpperCase(),
      defaultIncoterm: _incotermController.text.trim().isEmpty ? null : _incotermController.text.trim().toUpperCase(),
      version: widget.existingBuyer?.version,
    );
    ref.read(buyerFormControllerProvider.notifier).submit(draft: draft, existingId: widget.existingBuyer?.id);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(buyerFormControllerProvider, (previous, next) {
      if (next is BuyerFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is BuyerFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(buyerFormControllerProvider);
    final isSubmitting = formState is BuyerFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Buyer' : 'New Buyer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codeController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Buyer Code'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Buyer Name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _groupController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Group (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _countryController,
              enabled: !isSubmitting,
              maxLength: 2,
              decoration: const InputDecoration(labelText: 'Country code (e.g. US)'),
            ),
            TextFormField(
              controller: _currencyController,
              enabled: !isSubmitting,
              maxLength: 3,
              decoration: const InputDecoration(labelText: 'Default currency (e.g. USD)'),
            ),
            TextFormField(
              controller: _incotermController,
              enabled: !isSubmitting,
              maxLength: 3,
              decoration: const InputDecoration(labelText: 'Default Incoterm (e.g. FOB)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Save changes' : 'Create buyer'),
            ),
          ],
        ),
      ),
    );
  }
}
