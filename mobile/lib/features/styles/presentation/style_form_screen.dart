import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../application/style_form_controller.dart';
import '../domain/style.dart';

/// Document 7 (#30): create-only (see StyleFormController javadoc for the edit/
/// revision gap). Spec details are added afterwards as revisions from
/// StyleDetailScreen.
class StyleFormScreen extends ConsumerStatefulWidget {
  const StyleFormScreen({super.key});

  @override
  ConsumerState<StyleFormScreen> createState() => _StyleFormScreenState();
}

class _StyleFormScreenState extends ConsumerState<StyleFormScreen> {
  static const _genders = ['Men', 'Women', 'Unisex', 'Boys', 'Girls', 'Kids', 'Infant'];
  final _formKey = GlobalKey<FormState>();
  final _styleNoController = TextEditingController();
  int? _buyerId;
  int? _seasonId;
  final _buyerStyleNoController = TextEditingController();
  final _productCategoryController = TextEditingController();
  final _genderController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _styleNoController.dispose();
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
      buyerId: _buyerId!,
      buyerStyleNo: _buyerStyleNoController.text.trim().isEmpty ? null : _buyerStyleNoController.text.trim(),
      productCategory: _productCategoryController.text.trim().isEmpty ? null : _productCategoryController.text.trim(),
      seasonId: _seasonId,
      gender: _genderController.text.trim().isEmpty ? null : _genderController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );
    ref.read(styleFormControllerProvider.notifier).submit(draft);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(styleFormControllerProvider, (previous, next) {
      if (next is StyleFormSuccess) {
        showSuccessSnack(context, 'Style ${next.style.styleNo} created');
        Navigator.of(context).pop(next.style);
      } else if (next is StyleFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(styleFormControllerProvider);
    final isSubmitting = formState is StyleFormSubmitting;
    const module = AppModules.styles;
    autoSelectSingle(ref, buyerLookupProvider, current: _buyerId, apply: (id) {
      if (mounted && _buyerId == null) setState(() => _buyerId = id);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('New Style')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            FormSection(
              title: 'Style',
              icon: module.icon,
              color: module.color,
              children: [
                TextFormField(
                  controller: _styleNoController,
                  enabled: !isSubmitting,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Style number', hintText: 'e.g. ST-2026-001'),
                  validator: Validators.required('Style number'),
                ),
                LookupField(
                  label: 'Buyer',
                  icon: Icons.storefront_rounded,
                  required: true,
                  enabled: !isSubmitting,
                  initialValue: _buyerId,
                  options: buyerLookupProvider,
                  emptyMessage: 'No buyers yet. Add a buyer first from the Buyers screen.',
                  onChanged: (v) => _buyerId = v,
                ),
                TextFormField(
                  controller: _buyerStyleNoController,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: "Buyer's style number (optional)"),
                ),
              ],
            ),
            FormSection(
              title: 'Product',
              icon: Icons.category_outlined,
              color: module.color,
              children: [
                TextFormField(
                  controller: _productCategoryController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Product category (optional)',
                    hintText: 'e.g. Knit top, Denim bottom, Outerwear',
                  ),
                ),
                LookupField(
                  label: 'Season (optional)',
                  icon: Icons.wb_sunny_outlined,
                  enabled: !isSubmitting,
                  initialValue: _seasonId,
                  options: seasonLookupProvider,
                  emptyMessage: 'No seasons set up yet.',
                  onChanged: (v) => _seasonId = v,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _genderController.text.isEmpty ? null : _genderController.text,
                  decoration: const InputDecoration(labelText: 'Gender (optional)'),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('—')),
                    for (final g in _genders) DropdownMenuItem(value: g, child: Text(g)),
                  ],
                  onChanged: isSubmitting ? null : (v) => _genderController.text = v ?? '',
                ),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !isSubmitting,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Create style', icon: Icons.check_rounded, loading: isSubmitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
