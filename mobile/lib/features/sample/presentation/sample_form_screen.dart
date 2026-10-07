import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
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
  int? _buyerId;
  int? _styleId;
  int? _factoryId;
  int? _sampleTypeId;
  DateTime _requestDate = DateTime.now();
  DateTime? _requiredDate;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = SampleDraft(
      styleId: _styleId!,
      buyerId: _buyerId!,
      factoryId: _factoryId,
      sampleTypeId: _sampleTypeId!,
      requestDate: toApiDate(_requestDate)!,
      requiredDate: toApiDate(_requiredDate),
    );
    ref.read(sampleFormControllerProvider.notifier).submit(draft);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sampleFormControllerProvider, (previous, next) {
      if (next is SampleFormSuccess) {
        showSuccessSnack(context, 'Sample ${next.sample.sampleNo} requested');
        Navigator.of(context).pop(next.sample);
      } else if (next is SampleFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(sampleFormControllerProvider);
    final isSubmitting = formState is SampleFormSubmitting;
    const module = AppModules.sampling;
    autoSelectSingle(ref, buyerLookupProvider, current: _buyerId, apply: (id) {
      if (mounted && _buyerId == null) setState(() => _buyerId = id);
    });
    autoSelectSingle(ref, styleLookupProvider(_buyerId), current: _styleId, apply: (id) {
      if (mounted && _styleId == null) setState(() => _styleId = id);
    });
    autoSelectSingle(ref, sampleTypeLookupProvider, current: _sampleTypeId, apply: (id) {
      if (mounted && _sampleTypeId == null) setState(() => _sampleTypeId = id);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Request Sample')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            FormSection(
              title: 'What sample',
              icon: module.icon,
              color: module.color,
              children: [
                LookupField(
                  label: 'Buyer',
                  icon: Icons.storefront_rounded,
                  required: true,
                  enabled: !isSubmitting,
                  initialValue: _buyerId,
                  options: buyerLookupProvider,
                  onChanged: (v) => setState(() {
                    if (v != _buyerId) _styleId = null;
                    _buyerId = v;
                  }),
                ),
                LookupField(
                  key: ValueKey('style-$_buyerId'),
                  label: 'Style',
                  icon: Icons.checkroom_rounded,
                  required: true,
                  enabled: !isSubmitting,
                  initialValue: _styleId,
                  options: styleLookupProvider(_buyerId),
                  helperText: _buyerId == null ? 'Tip: pick the buyer first to narrow the list' : null,
                  emptyMessage: 'This buyer has no styles yet.',
                  onChanged: (v) => setState(() => _styleId = v),
                ),
                LookupField(
                  label: 'Sample type',
                  icon: Icons.category_outlined,
                  required: true,
                  enabled: !isSubmitting,
                  initialValue: _sampleTypeId,
                  options: sampleTypeLookupProvider,
                  emptyMessage: 'No sample types are set up. Ask an admin to add them in master data.',
                  onChanged: (v) => setState(() => _sampleTypeId = v),
                ),
                LookupField(
                  label: 'Factory',
                  icon: Icons.factory_outlined,
                  enabled: !isSubmitting,
                  initialValue: _factoryId,
                  options: factoryLookupProvider,
                  helperText: 'Who will make the sample',
                  onChanged: (v) => setState(() => _factoryId = v),
                ),
              ],
            ),
            FormSection(
              title: 'Dates',
              icon: Icons.event_rounded,
              color: module.color,
              children: [
                DateField(
                  label: 'Request date',
                  required: true,
                  enabled: !isSubmitting,
                  value: _requestDate,
                  onChanged: (d) => setState(() => _requestDate = d ?? _requestDate),
                ),
                DateField(
                  label: 'Required by',
                  enabled: !isSubmitting,
                  value: _requiredDate,
                  firstDate: _requestDate,
                  helperText: 'When the buyer needs it',
                  onChanged: (d) => setState(() => _requiredDate = d),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Request sample', icon: Icons.send_rounded, loading: isSubmitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
