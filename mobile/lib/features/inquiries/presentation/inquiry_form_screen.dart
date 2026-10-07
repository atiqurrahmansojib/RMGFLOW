import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../activity/presentation/activity_list_screen.dart';
import '../../task/presentation/task_list_screen.dart';
import '../application/inquiry_form_controller.dart';
import '../domain/inquiry.dart';
import 'inquiry_factory_candidates_screen.dart';
import 'inquiry_status_actions.dart';

/// Document 7 (#26-27): single form for create/edit, plus a status-change action
/// for existing inquiries (Doc 10.1 state machine — the backend enforces which
/// transitions are legal; this UI offers every other status and lets a 400
/// surface via the Failure/SnackBar path if the user picks an invalid one).
class InquiryFormScreen extends ConsumerStatefulWidget {
  const InquiryFormScreen({super.key, this.existingInquiry});

  final Inquiry? existingInquiry;

  @override
  ConsumerState<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends ConsumerState<InquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _inquiryNoController;
  late final TextEditingController _targetQuantityController;
  late final TextEditingController _targetPriceController;
  late final TextEditingController _targetCurrencyController;
  late final TextEditingController _deliveryController;
  int? _buyerId;

  bool get _isEdit => widget.existingInquiry != null;

  @override
  void initState() {
    super.initState();
    final inquiry = widget.existingInquiry;
    // New inquiries get the year prefix so only the running number is typed.
    _inquiryNoController = TextEditingController(text: inquiry?.inquiryNo ?? 'INQ-${DateTime.now().year}-');
    _buyerId = inquiry?.buyerId;
    _targetQuantityController = TextEditingController(text: inquiry?.targetQuantity?.toString());
    _targetPriceController = TextEditingController(text: inquiry?.targetPrice?.toString());
    _targetCurrencyController = TextEditingController(text: inquiry?.targetCurrency ?? 'USD');
    _deliveryController = TextEditingController(text: inquiry?.deliveryRequirement);
  }

  @override
  void dispose() {
    _inquiryNoController.dispose();
    _targetQuantityController.dispose();
    _targetPriceController.dispose();
    _targetCurrencyController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existingInquiry;
    final draft = InquiryDraft(
      inquiryNo: _inquiryNoController.text.trim(),
      buyerId: _buyerId!,
      // Not editable on mobile — carried over so an edit never wipes them.
      seasonId: existing?.seasonId,
      merchandiserId: existing?.merchandiserId,
      targetQuantity: int.tryParse(_targetQuantityController.text.trim()),
      targetPrice: double.tryParse(_targetPriceController.text.trim()),
      targetCurrency: blankToNull(_targetCurrencyController.text)?.toUpperCase(),
      deliveryRequirement: blankToNull(_deliveryController.text),
    );
    ref.read(inquiryFormControllerProvider.notifier).submit(draft: draft, existingId: existing?.id);
  }

  Future<void> _showStatusDialog([InquiryStatus? target]) async {
    final inquiry = widget.existingInquiry!;
    final pick = await pickInquiryStatus(context, inquiry, target: target, confirm: target == null);
    if (pick == null || !mounted) return;
    ref.read(inquiryFormControllerProvider.notifier).changeStatus(inquiry.id, pick.status, lostReason: pick.lostReason);
  }

  void _openCandidates() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => InquiryFactoryCandidatesScreen(inquiry: widget.existingInquiry!)),
      );

  @override
  Widget build(BuildContext context) {
    ref.listen(inquiryFormControllerProvider, (previous, next) {
      if (next is InquiryFormSuccess) {
        showSuccessSnack(
            context, _isEdit ? 'Inquiry ${next.inquiry.inquiryNo} saved' : 'Inquiry ${next.inquiry.inquiryNo} created');
        Navigator.of(context).pop(_isEdit ? true : next.inquiry);
      } else if (next is InquiryFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(inquiryFormControllerProvider);
    final isSubmitting = formState is InquiryFormSubmitting;
    const module = AppModules.inquiries;
    final existing = widget.existingInquiry;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Inquiry' : 'New Inquiry'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Factory candidates',
              icon: const Icon(Icons.factory_outlined),
              onPressed: _openCandidates,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            if (existing != null) ...[
              GradientHeader.module(
                module,
                margin: EdgeInsets.zero,
                eyebrow: 'Inquiry · ${existing.inquiryNo}',
                title: existing.buyerName,
                subtitle: existing.deliveryRequirement,
                trailing: StatusChip(existing.status.apiValue, label: existing.status.label),
                bottom: Row(
                  children: [
                    Expanded(
                      child: HeaderStat(
                        value: existing.targetQuantity == null ? '—' : '${existing.targetQuantity}',
                        label: 'Target pcs',
                      ),
                    ),
                    Expanded(
                      child: HeaderStat(
                        value: existing.targetPrice == null
                            ? '—'
                            : formatMoney(existing.targetCurrency, existing.targetPrice),
                        label: 'Target price',
                      ),
                    ),
                  ],
                ),
              ),
              SectionHeader(
                'Status',
                icon: Icons.sync_alt_rounded,
                accentColor: module.color,
                trailing: StatusMenuChip<InquiryStatus>(
                  status: existing.status.apiValue,
                  label: existing.status.label,
                  dense: false,
                  enabled: !isSubmitting,
                  options: nextInquiryStatuses(existing),
                  apiValueOf: (s) => s.apiValue,
                  labelOf: (s) => s.label,
                  onSelected: _showStatusDialog,
                ),
              ),
              if (existing.lostReason != null)
                AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InfoRow(label: 'Lost reason', value: existing.lostReason, vertical: true),
                ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final s in nextInquiryStatuses(existing))
                    ActionChip(
                      avatar: Icon(AppStatus.resolve(s.apiValue).icon, size: 18, color: AppStatus.color(s.apiValue)),
                      label: Text('Mark ${s.label.toLowerCase()}'),
                      onPressed: isSubmitting ? null : () => _showStatusDialog(s),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              LinkCard(
                icon: Icons.factory_outlined,
                color: AppModules.factories.color,
                title: 'Factory candidates',
                subtitle: 'Shortlist factories to quote and select the winner',
                onTap: _openCandidates,
              ),
              RecordLinks(
                tasks: () => TaskListScreen(target: (entityType: 'Inquiry', entityId: existing.id)),
                activity: () => ActivityListScreen(entityType: 'Inquiry', entityId: existing.id),
              ),
            ],
            FormSection(
              title: 'Inquiry',
              icon: Icons.mark_email_unread_outlined,
              color: module.color,
              children: [
                TextFormField(
                  controller: _inquiryNoController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Inquiry number', hintText: 'e.g. INQ-2026-001'),
                  validator: (v) =>
                      Validators.required('Inquiry number')(v) ??
                      (v!.trim().endsWith('-') ? 'Add the running number after the prefix' : null),
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
              ],
            ),
            FormSection(
              title: 'Targets',
              subtitle: 'What the buyer is asking for',
              icon: Icons.flag_outlined,
              color: module.color,
              children: [
                TextFormField(
                  controller: _targetQuantityController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: NumberInput.integer,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Target quantity (optional)', suffixText: 'pcs'),
                  validator: Validators.positiveInt(required: false),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _targetPriceController,
                        enabled: !isSubmitting,
                        keyboardType: NumberInput.decimalKeyboard,
                        inputFormatters: NumberInput.decimal,
                        textInputAction: TextInputAction.next,
                        decoration:
                            const InputDecoration(labelText: 'Target price (optional)', helperText: 'Per piece'),
                        validator: Validators.money(required: false, what: 'Target price'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: CodePickerField(
                        controller: _targetCurrencyController,
                        label: 'Currency',
                        codes: currencyCodesProvider,
                        required: false,
                        enabled: !isSubmitting,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _deliveryController,
                  enabled: !isSubmitting,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Delivery requirement (optional)',
                    hintText: 'e.g. Ex-factory by mid-March, sea freight',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: _isEdit ? 'Save changes' : 'Create inquiry',
              icon: Icons.check_rounded,
              loading: isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
