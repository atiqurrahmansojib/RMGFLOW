import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../activity/presentation/activity_list_screen.dart';
import '../../task/presentation/task_list_screen.dart';
import '../application/factory_form_controller.dart';
import '../domain/factory.dart';
import 'factory_profile_screen.dart';

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
    // Most partner factories are in Bangladesh — prefill for new records.
    _countryController = TextEditingController(text: factory == null ? 'BD' : factory.country);
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

  void _openProfile() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FactoryProfileScreen(factory: widget.existingFactory!)),
      );

  Future<void> _confirmDeactivate() async {
    final ok = await confirmAction(
      context,
      title: 'Deactivate factory?',
      message: '${widget.existingFactory!.name} will no longer be offered when placing new orders. '
          'Existing orders are kept.',
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    if (ok) ref.read(factoryFormControllerProvider.notifier).deactivate(widget.existingFactory!.id);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(factoryFormControllerProvider, (previous, next) {
      if (next is FactoryFormSuccess) {
        showSuccessSnack(context, _isEdit ? 'Factory updated' : 'Factory ${next.factory.name} created');
        Navigator.of(context).pop(next.factory);
      } else if (next is FactoryFormDeactivated) {
        showSuccessSnack(context, 'Factory deactivated');
        Navigator.of(context).pop(true);
      } else if (next is FactoryFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(factoryFormControllerProvider);
    final isSubmitting = formState is FactoryFormSubmitting;
    final factory = widget.existingFactory;
    const module = AppModules.factories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Factory' : 'New Factory'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Contacts, capabilities & approvals',
              icon: const Icon(Icons.badge_outlined),
              onPressed: _openProfile,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            if (factory != null) ...[
              GradientHeader.module(
                module,
                margin: EdgeInsets.zero,
                eyebrow: '${factory.partnerType.label} · ${factory.code}',
                title: factory.name,
                subtitle: factory.address ?? factory.legalEntityName,
                trailing: StatusChip(factory.active ? 'ACTIVE' : 'INACTIVE'),
                bottom: Row(
                  children: [
                    Expanded(
                      child:
                          HeaderStat(value: factory.capacityPerMonth?.toString() ?? '—', label: 'Capacity (pcs/month)'),
                    ),
                    Expanded(child: HeaderStat(value: factory.country ?? '—', label: 'Country')),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LinkCard(
                icon: Icons.badge_outlined,
                color: AppColors.teal,
                title: 'Contacts, capabilities & compliance',
                subtitle: 'People, product categories, certifications and buyer approvals',
                onTap: _openProfile,
              ),
              RecordLinks(
                tasks: () => TaskListScreen(target: (entityType: 'Factory', entityId: factory.id)),
                activity: () => ActivityListScreen(entityType: 'Factory', entityId: factory.id),
              ),
            ],
            FormSection(
              title: 'Identity',
              icon: Icons.badge_outlined,
              color: module.color,
              children: [
                DropdownButtonFormField<PartnerType>(
                  initialValue: _partnerType,
                  decoration: const InputDecoration(labelText: 'Partner type'),
                  items: PartnerType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                  onChanged: isSubmitting ? null : (value) => setState(() => _partnerType = value!),
                ),
                TextFormField(
                  controller: _codeController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(labelText: 'Factory code', hintText: 'Short unique code, e.g. FAC-01'),
                  validator: Validators.required('Factory code'),
                ),
                TextFormField(
                  controller: _nameController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: Validators.required('Name'),
                ),
                TextFormField(
                  controller: _legalEntityController,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Legal entity name (optional)'),
                ),
              ],
            ),
            FormSection(
              title: 'Location & capacity',
              icon: Icons.location_on_outlined,
              color: module.color,
              children: [
                TextFormField(
                  controller: _addressController,
                  enabled: !isSubmitting,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Address (optional)'),
                ),
                TextFormField(
                  controller: _countryController,
                  enabled: !isSubmitting,
                  maxLength: 2,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(labelText: 'Country code (optional)', hintText: '2 letters, e.g. BD'),
                  validator: (v) =>
                      (v != null && v.trim().isNotEmpty && v.trim().length != 2) ? 'Use the 2-letter ISO code' : null,
                ),
                TextFormField(
                  controller: _capacityController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: NumberInput.integer,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Capacity per month (optional)', suffixText: 'pcs'),
                  validator: Validators.positiveInt(required: false, what: 'Capacity'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: _isEdit ? 'Save changes' : 'Create factory',
              icon: Icons.check_rounded,
              loading: isSubmitting,
              onPressed: _submit,
            ),
            if (factory != null && factory.active) ...[
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Deactivate factory',
                icon: Icons.block_rounded,
                variant: ButtonVariant.danger,
                onPressed: isSubmitting ? null : _confirmDeactivate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
