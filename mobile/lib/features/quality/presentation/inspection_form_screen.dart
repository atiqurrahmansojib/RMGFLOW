import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/widgets.dart';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_inspectionType == InspectionType.final_ && _result != InspectionResult.pass) {
      final ok = await confirmAction(
        context,
        title: 'Save a ${_result.label.toLowerCase()} final inspection?',
        message: 'A final inspection that is not a pass blocks shipment of this order until it is re-inspected '
            'or a permitted user overrides the quality gate.',
        confirmLabel: 'Save inspection',
        destructive: true,
      );
      if (!ok) return;
    }
    final draft = InspectionDraft(
      inspectionType: _inspectionType,
      inspectionDate: toApiDate(_inspectionDate)!,
      inspectedQty: int.parse(_inspectedQtyController.text.trim()),
      aqlLevel: blankToNull(_aqlLevelController.text),
      result: _result,
    );
    ref.read(inspectionFormControllerProvider.notifier).submit(widget.orderId, draft);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(inspectionFormControllerProvider, (previous, next) {
      if (next is InspectionFormSuccess) {
        showSuccessSnack(context, 'Inspection saved');
        Navigator.of(context).pop(next.inspection);
      } else if (next is InspectionFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(inspectionFormControllerProvider);
    final isSubmitting = formState is InspectionFormSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Inspection')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            SectionHeader('Inspection', icon: AppModules.quality.icon, accentColor: AppModules.quality.color),
            AppCard(
              accentColor: AppModules.quality.color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Inspection type', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<InspectionType>(
                    segments: InspectionType.values.map((t) => ButtonSegment(value: t, label: Text(t.label))).toList(),
                    selected: {_inspectionType},
                    onSelectionChanged: isSubmitting ? null : (s) => setState(() => _inspectionType = s.first),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DateField(
                    label: 'Inspection date',
                    required: true,
                    enabled: !isSubmitting,
                    value: _inspectionDate,
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    onChanged: (d) => setState(() => _inspectionDate = d ?? _inspectionDate),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _inspectedQtyController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    inputFormatters: NumberInput.integer,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Inspected quantity', suffixText: 'pcs'),
                    validator: Validators.positiveInt(what: 'Inspected quantity'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _aqlLevelController,
                    enabled: !isSubmitting,
                    keyboardType: NumberInput.decimalKeyboard,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(labelText: 'AQL level (optional)', hintText: 'e.g. 2.5'),
                  ),
                ],
              ),
            ),
            SectionHeader('Result', icon: Icons.rule_rounded, accentColor: AppStatus.color(_result.apiValue)),
            AppCard(
              accentColor: AppStatus.color(_result.apiValue),
              child: SegmentedButton<InspectionResult>(
                segments: InspectionResult.values
                    .map((r) => ButtonSegment(
                          value: r,
                          label: Text(r.label),
                          icon: Icon(AppStatus.resolve(r.apiValue).icon),
                        ))
                    .toList(),
                selected: {_result},
                onSelectionChanged: isSubmitting ? null : (s) => setState(() => _result = s.first),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
                label: 'Save inspection', icon: Icons.check_rounded, loading: isSubmitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
