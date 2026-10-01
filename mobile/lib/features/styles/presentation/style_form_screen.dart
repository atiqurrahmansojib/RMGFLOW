import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/style_form_controller.dart';
import '../domain/style.dart';

/// Document 7 (#30): create-only (see StyleFormController javadoc for the edit/
/// revision gap).
class StyleFormScreen extends ConsumerStatefulWidget {
  const StyleFormScreen({super.key});

  @override
  ConsumerState<StyleFormScreen> createState() => _StyleFormScreenState();
}

class _StyleFormScreenState extends ConsumerState<StyleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _styleNoController = TextEditingController();
  final _buyerIdController = TextEditingController();
  final _buyerStyleNoController = TextEditingController();
  final _productCategoryController = TextEditingController();
  final _genderController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _styleNoController.dispose();
    _buyerIdController.dispose();
    _buyerStyleNoController.dispose();
    _productCategoryController.dispose();
    _genderController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = StyleDraft(
      styleNo: _styleNoController.text.trim(),
      buyerId: int.parse(_buyerIdController.text.trim()),
      buyerStyleNo: _buyerStyleNoController.text.trim().isEmpty ? null : _buyerStyleNoController.text.trim(),
      productCategory: _productCategoryController.text.trim().isEmpty ? null : _productCategoryController.text.trim(),
      gender: _genderController.text.trim().isEmpty ? null : _genderController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );
    ref.read(styleFormControllerProvider.notifier).submit(draft);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(styleFormControllerProvider, (previous, next) {
      if (next is StyleFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is StyleFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final formState = ref.watch(styleFormControllerProvider);
    final isSubmitting = formState is StyleFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('New Style')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _styleNoController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Style Number'),
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
              controller: _buyerStyleNoController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: "Buyer's style number (optional)"),
            ),
            TextFormField(
              controller: _productCategoryController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Product category (optional)'),
            ),
            TextFormField(
              controller: _genderController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(labelText: 'Gender (optional)'),
            ),
            TextFormField(
              controller: _descriptionController,
              enabled: !isSubmitting,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create style'),
            ),
          ],
        ),
      ),
    );
  }
}
