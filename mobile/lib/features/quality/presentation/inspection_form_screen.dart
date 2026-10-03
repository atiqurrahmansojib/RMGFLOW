import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/inspection_controller.dart';
import '../domain/quality.dart';

/// Document 7 (#59-60): record an inspection — inline/midline/final.
class InspectionFormScreen extends ConsumerStatefulWidget {
  const InspectionFormScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends ConsumerState<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  InspectionType _inspectionType = InspectionType.inline;
  InspectionResult _result = InspectionResult.pass;
  DateTime _inspectionDate = DateTime.now();
  final _inspectedQtyController = TextEditingController();
  final _aqlLevelController = TextEditingController();

  @override
  void dispose() {
    _inspectedQtyController.dispose();
    _aqlLevelController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = InspectionDraft(
      inspectionType: _inspectionType,
      inspectionDate: _inspectionDate.toIso8601String().split('T').first,
      inspectedQty: int.parse(_inspectedQtyController.text.trim()),
      aqlLevel: _aqlLevelController.text.trim().isEmpty ? null : _aqlLevelController.text.trim(),
      result: _result,
    );
    ref.read(inspectionFormControllerProvider.notifier).submit(widget.orderId, draft);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(inspectionFormControllerProvider, (previous, next) {
      if (next is InspectionFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is InspectionFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(inspectionFormControllerProvider);
    final isSubmitting = formState is InspectionFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Inspection')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<InspectionType>(
              value: _inspectionType,
              decoration: const InputDecoration(labelText: 'Inspection Type'),
              items: InspectionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: isSubmitting ? null : (v) => setState(() => _inspectionType = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Inspection date'),
              subtitle: Text(_inspectionDate.toIso8601String().split('T').first),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSubmitting
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _inspectionDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _inspectionDate = picked);
                    },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _inspectedQtyController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Inspected Quantity'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aqlLevelController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'AQL Level (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InspectionResult>(
              value: _result,
              decoration: const InputDecoration(labelText: 'Result'),
              items: InspectionResult.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
              onChanged: isSubmitting ? null : (v) => setState(() => _result = v!),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save inspection'),
            ),
          ],
        ),
      ),
    );
  }
}
