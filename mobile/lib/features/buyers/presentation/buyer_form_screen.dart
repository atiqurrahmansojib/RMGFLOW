import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../activity/presentation/activity_list_screen.dart';
import '../../task/presentation/task_list_screen.dart';
import '../application/buyer_form_controller.dart';
import '../domain/buyer.dart';
import 'buyer_contacts_screen.dart';

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
    _currencyController = TextEditingController(text: buyer == null ? 'USD' : buyer.defaultCurrency);
    _incotermController = TextEditingController(text: buyer == null ? 'FOB' : buyer.defaultIncoterm);
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

  void _openContacts() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BuyerContactsScreen(buyer: widget.existingBuyer!)),
      );

  Future<void> _confirmDeactivate() async {
    final ok = await confirmAction(
      context,
      title: 'Deactivate buyer?',
      message: '${widget.existingBuyer!.name} will no longer appear in pickers for new inquiries and orders. '
          'Existing records are kept.',
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    if (ok) ref.read(buyerFormControllerProvider.notifier).deactivate(widget.existingBuyer!.id);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(buyerFormControllerProvider, (previous, next) {
      if (next is BuyerFormSuccess) {
        showSuccessSnack(context, _isEdit ? 'Buyer updated' : 'Buyer ${next.buyer.name} created');
        Navigator.of(context).pop(next.buyer);
      } else if (next is BuyerFormDeactivated) {
        showSuccessSnack(context, 'Buyer deactivated');
        Navigator.of(context).pop(true);
      } else if (next is BuyerFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(buyerFormControllerProvider);
    final isSubmitting = formState is BuyerFormSubmitting;
    final buyer = widget.existingBuyer;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Buyer' : 'New Buyer'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Contacts',
              icon: const Icon(Icons.contacts_outlined),
              onPressed: _openContacts,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            if (buyer != null) ...[
              GradientHeader.module(
                AppModules.buyers,
                margin: EdgeInsets.zero,
                eyebrow: 'Buyer · ${buyer.code}',
                title: buyer.name,
                subtitle: buyer.groupName ?? buyer.country,
                trailing: StatusChip(buyer.active ? 'ACTIVE' : 'INACTIVE'),
                bottom: Row(
                  children: [
                    Expanded(child: HeaderStat(value: buyer.defaultCurrency ?? '—', label: 'Currency')),
                    Expanded(child: HeaderStat(value: buyer.defaultIncoterm ?? '—', label: 'Incoterm')),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LinkCard(
                icon: Icons.contacts_outlined,
                color: AppColors.teal,
                title: 'Contacts',
                subtitle: 'Merchandisers, QA and accounts people at this buyer',
                onTap: _openContacts,
              ),
              RecordLinks(
                tasks: () => TaskListScreen(target: (entityType: 'Buyer', entityId: buyer.id)),
                activity: () => ActivityListScreen(entityType: 'Buyer', entityId: buyer.id),
              ),
            ],
            FormSection(
              title: 'Identity',
              icon: Icons.badge_outlined,
              color: AppModules.buyers.color,
              children: [
                TextFormField(
                  controller: _codeController,
                  enabled: !isSubmitting,
                  autofocus: !_isEdit,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Buyer code', hintText: 'Short unique code, e.g. HM'),
                  validator: Validators.required('Buyer code'),
                ),
                TextFormField(
                  controller: _nameController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Buyer name', hintText: 'e.g. H&M Hennes & Mauritz'),
                  validator: Validators.required('Buyer name'),
                ),
                TextFormField(
                  controller: _groupController,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Group (optional)'),
                ),
              ],
            ),
            FormSection(
              title: 'Trade defaults',
              subtitle: 'Pre-filled on new inquiries, quotations and orders',
              icon: Icons.public_rounded,
              color: AppModules.buyers.color,
              children: [
                CodePickerField(
                  controller: _countryController,
                  label: 'Country',
                  codes: countryCodesProvider,
                  names: referenceNamesProvider('/countries'),
                  codeLength: 2,
                  required: false,
                  enabled: !isSubmitting,
                ),
                CodePickerField(
                  controller: _currencyController,
                  label: 'Default currency',
                  codes: currencyCodesProvider,
                  names: referenceNamesProvider('/currencies'),
                  required: false,
                  enabled: !isSubmitting,
                ),
                CodePickerField(
                  controller: _incotermController,
                  label: 'Default Incoterm',
                  codes: incotermCodesProvider,
                  names: referenceNamesProvider('/incoterms'),
                  required: false,
                  enabled: !isSubmitting,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: _isEdit ? 'Save changes' : 'Create buyer',
              icon: Icons.check_rounded,
              loading: isSubmitting,
              onPressed: _submit,
            ),
            if (buyer != null && buyer.active) ...[
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Deactivate buyer',
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
