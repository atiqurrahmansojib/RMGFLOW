import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/sample_form_controller.dart';
import '../domain/sample.dart';

/// Document 7 (#32): create-only form — no edit endpoint exists server-side.
class SampleFormScreen extends ConsumerStatefulWidget {
  const SampleFormScreen({super.key});

  @override
  ConsumerState<SampleFormScreen> createState() => _SampleFormScreenState();
}

class _SampleFormScreenState extends ConsumerState<SampleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _styleIdController = TextEditingController();
  final _buyerIdController = TextEditingController();
  final _factoryIdController = TextEditingController();
  final _sampleTypeIdController = TextEditingController();
  DateTime _requestDate = DateTime.now();
  DateTime? _requiredDate;

  @override
  void dispose() {
    _styleIdController.dispose();
    _buyerIdController.dispose();
    _factoryIdController.dispose();
    _sampleTypeIdController.dispose();
    super.dispose();
  }

  String _iso(DateTime d) => d.toIso8601String().split('T').first;

  Future<void> _pickDate({required bool isRequiredDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isRequiredDate ? (_requiredDate ?? _requestDate) : _requestDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => isRequiredDate ? _requiredDate = picked : _requestDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = SampleDraft(
      styleId: int.parse(_styleIdController.text.trim()),
      buyerId: int.parse(_buyerIdController.text.trim()),
      factoryId: int.tryParse(_factoryIdController.text.trim()),
      sampleTypeId: int.parse(_sampleTypeIdController.text.trim()),
      requestDate: _iso(_requestDate),
      requiredDate: _requiredDate != null ? _iso(_requiredDate!) : null,
    );
    ref.read(sampleFormControllerProvider.notifier).submit(draft);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sampleFormControllerProvider, (previous, next) {
      if (next is SampleFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is SampleFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(sampleFormControllerProvider);
    final isSubmitting = formState is SampleFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Sample')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _styleIdController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Style ID'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _buyerIdController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Buyer ID'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _factoryIdController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Factory ID (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sampleTypeIdController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sample Type ID'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Request date'),
              subtitle: Text(_iso(_requestDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSubmitting ? null : () => _pickDate(isRequiredDate: false),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Required date (optional)'),
              subtitle: Text(_requiredDate != null ? _iso(_requiredDate!) : 'Not set'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSubmitting ? null : () => _pickDate(isRequiredDate: true),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Request sample'),
            ),
          ],
        ),
      ),
    );
  }
}
