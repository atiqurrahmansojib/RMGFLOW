import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/production_controller.dart';
import '../domain/production_update.dart';

/// Document 7 (#53): daily production-update entry — one row per line stage.
class ProductionUpdateFormScreen extends ConsumerStatefulWidget {
  const ProductionUpdateFormScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ProductionUpdateFormScreen> createState() => _ProductionUpdateFormScreenState();
}

class _ProductionUpdateFormScreenState extends ConsumerState<ProductionUpdateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _updateDate = DateTime.now();
  final _cuttingController = TextEditingController(text: '0');
  final _sewingController = TextEditingController(text: '0');
  final _finishingController = TextEditingController(text: '0');
  final _packingController = TextEditingController(text: '0');
  final _rejectionController = TextEditingController(text: '0');
  final _alterationController = TextEditingController(text: '0');

  @override
  void dispose() {
    _cuttingController.dispose();
    _sewingController.dispose();
    _finishingController.dispose();
    _packingController.dispose();
    _rejectionController.dispose();
    _alterationController.dispose();
    super.dispose();
  }

  String _iso(DateTime d) => d.toIso8601String().split('T').first;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = ProductionUpdateDraft(
      updateDate: _iso(_updateDate),
      cuttingQty: int.parse(_cuttingController.text.trim()),
      sewingQty: int.parse(_sewingController.text.trim()),
      finishingQty: int.parse(_finishingController.text.trim()),
      packingQty: int.parse(_packingController.text.trim()),
      rejectionQty: int.parse(_rejectionController.text.trim()),
      alterationQty: int.parse(_alterationController.text.trim()),
    );
    ref.read(productionUpdateFormControllerProvider.notifier).submit(widget.orderId, draft);
  }

  Widget _qtyField(TextEditingController controller, String label, bool isSubmitting) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          enabled: !isSubmitting,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    ref.listen(productionUpdateFormControllerProvider, (previous, next) {
      if (next is ProductionUpdateFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is ProductionUpdateFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(productionUpdateFormControllerProvider);
    final isSubmitting = formState is ProductionUpdateFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Production Update')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Update date'),
              subtitle: Text(_iso(_updateDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSubmitting
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _updateDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _updateDate = picked);
                    },
            ),
            const SizedBox(height: 12),
            _qtyField(_cuttingController, 'Cutting qty', isSubmitting),
            _qtyField(_sewingController, 'Sewing qty', isSubmitting),
            _qtyField(_finishingController, 'Finishing qty', isSubmitting),
            _qtyField(_packingController, 'Packing qty', isSubmitting),
            _qtyField(_rejectionController, 'Rejection qty', isSubmitting),
            _qtyField(_alterationController, 'Alteration qty', isSubmitting),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save update'),
            ),
          ],
        ),
      ),
    );
  }
}
