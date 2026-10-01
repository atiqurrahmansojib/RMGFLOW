import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/factory_form_controller.dart';
import '../domain/factory.dart';

/// Document 7 (#22): single form for create and edit, mirroring BuyerFormScreen's pattern.
class FactoryFormScreen extends ConsumerStatefulWidget {
  const FactoryFormScreen({super.key, this.existingFactory});

  final Factory? existingFactory;

  @override
  ConsumerState<FactoryFormScreen> createState() => _FactoryFormScreenState();
}

class _FactoryFormScreenState extends ConsumerState<FactoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _legalEntityController;
  late final TextEditingController _addressController;
  late final TextEditingController _countryController;
  late final TextEditingController _capacityController;
  late PartnerType _partnerType;

  bool get _isEdit => widget.existingFactory != null;

  @override
  void initState() {
    super.initState();
    final factory = widget.existingFactory;
    _codeController = TextEditingController(text: factory?.code);
    _nameController = TextEditingController(text: factory?.name);
    _legalEntityController = TextEditingController(text: factory?.legalEntityName);
    _addressController = TextEditingController(text: factory?.address);
    _countryController = TextEditingController(text: factory?.country);
    _capacityController = TextEditingController(text: factory?.capacityPerMonth?.toString());
    _partnerType = factory?.partnerType ?? PartnerType.garmentFactory;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _legalEntityController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = FactoryDraft(
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      partnerType: _partnerType,
      legalEntityName: _legalEntityController.text.trim().isEmpty ? null : _legalEntityController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim().toUpperCase(),
      capacityPerMonth: int.tryParse(_capacityController.text.trim()),
      version: widget.existingFactory?.version,
    );
    ref.read(factoryFormControllerProvider.notifier).submit(draft: draft, existingId: widget.existingFactory?.id);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(factoryFormControllerProvider, (previous, next) {
      if (next is FactoryFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is FactoryFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(factoryFormControllerProvider);
    final isSubmitting = formState is FactoryFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Factory' : 'New Factory')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<PartnerType>(
              value: _partnerType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: PartnerType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: isSubmitting ? null : (value) => setState(() => _partnerType = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codeController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Factory Code'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _legalEntityController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Legal entity name (optional)'),
            ),
            TextFormField(
              controller: _addressController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Address (optional)'),
            ),
            TextFormField(
              controller: _countryController,
              enabled: !isSubmitting,
              maxLength: 2,
              decoration: const InputDecoration(labelText: 'Country code (e.g. BD)'),
            ),
            TextFormField(
              controller: _capacityController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacity per month (optional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Save changes' : 'Create factory'),
            ),
          ],
        ),
      ),
    );
  }
}
