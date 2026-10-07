import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../application/defect_controller.dart';
import '../domain/quality.dart';
import 'capa_list_screen.dart';

/// Document 7 (#60-61): defects logged against one inspection, with a
/// log-defect sheet and a link into that defect's CAPA records.
class DefectListScreen extends ConsumerWidget {
  const DefectListScreen({super.key, required this.inspection});

  final Inspection inspection;

  static const severities = ['MINOR', 'MAJOR', 'CRITICAL'];

  Future<void> _addDefect(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<DefectDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _DefectSheet(),
    );
    if (draft == null) return;
    await ref.read(defectFormControllerProvider.notifier).submit(inspection.id, draft);
    if (context.mounted && ref.read(defectFormControllerProvider) is DefectFormSuccess) {
      showSuccessSnack(context, 'Defect logged');
    }
    ref.read(defectListControllerProvider(inspection.id).notifier).refresh();
  }

  StatusTone _tone(String severity) => switch (severity.toUpperCase()) {
        'CRITICAL' => StatusTone.danger,
        'MAJOR' => StatusTone.warning,
        _ => StatusTone.neutral,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(defectFormControllerProvider, (previous, next) {
      if (next is DefectFormFailed) showErrorSnack(context, next.failure.message);
    });
    final state = ref.watch(defectListControllerProvider(inspection.id));

    return Scaffold(
      appBar: AppBar(title: Text('${inspection.inspectionType.label} Defects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDefect(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log defect'),
      ),
      body: switch (state) {
        DefectListLoading() => const LoadingView(),
        DefectListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(defectListControllerProvider(inspection.id).notifier).refresh(),
          ),
        DefectListLoaded(:final defects) when defects.isEmpty => EmptyStateView(
            title: 'No defects logged',
            message: 'Log each defect type found during this inspection with its quantity and severity.',
            icon: Icons.bug_report_outlined,
            color: AppModules.quality.color,
            actionLabel: 'Log defect',
            onAction: () => _addDefect(context, ref),
          ),
        DefectListLoaded(:final defects) => RefreshIndicator(
            onRefresh: () => ref.read(defectListControllerProvider(inspection.id).notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.listWithFab.copyWith(left: 0, right: 0, top: 0),
              children: [
                GradientHeader.module(
                  AppModules.quality,
                  eyebrow:
                      '${inspection.inspectionType.label} inspection · ${formatApiDate(inspection.inspectionDate)}',
                  title: '${fmtQty(defects.fold<int>(0, (s, d) => s + d.quantity))} defective pcs',
                  subtitle: '${defects.length} defect type${defects.length == 1 ? '' : 's'} · '
                      '${fmtQty(inspection.inspectedQty)} pcs inspected',
                  trailing: StatusChip(inspection.result.apiValue, label: inspection.result.label),
                  bottom: Row(
                    children: [
                      for (final sev in severities) ...[
                        HeaderStat(
                          value: '${defects.where((d) => d.severity.toUpperCase() == sev).length}',
                          label: AppStatus.humanize(sev),
                        ),
                        const SizedBox(width: AppSpacing.xxl),
                      ],
                    ],
                  ),
                ),
                for (final defect in defects)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AppCard(
                      accentColor: _tone(defect.severity).color,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CapaListScreen(defectId: defect.id)),
                      ),
                      child: RecordRow(
                        leading: IconBadge(icon: Icons.bug_report_rounded, color: _tone(defect.severity).color),
                        title: lookupLabel(ref, defectTypeLookupProvider, defect.defectTypeId,
                            fallback: 'Defect type #${defect.defectTypeId}'),
                        subtitle: '${fmtQty(defect.quantity)} pcs',
                        meta: 'Tap for CAPA (corrective action)',
                        trailing: StatusChip(defect.severity, tone: _tone(defect.severity), dense: true),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      },
    );
  }
}

class _DefectSheet extends ConsumerStatefulWidget {
  const _DefectSheet();

  @override
  ConsumerState<_DefectSheet> createState() => _DefectSheetState();
}

class _DefectSheetState extends ConsumerState<_DefectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  int? _typeId;
  String _severity = 'MINOR';

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  /// Defaults severity from the defect type's configured severity, if any.
  void _onType(int? id) {
    setState(() => _typeId = id);
    final types = ref.read(defectTypeLookupProvider).valueOrNull ?? const [];
    for (final t in types) {
      if (t.id != id) continue;
      final sub = t.subtitle?.toUpperCase() ?? '';
      for (final s in DefectListScreen.severities) {
        if (sub.contains(s)) setState(() => _severity = s);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log defect', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              LookupField(
                label: 'Defect type',
                icon: Icons.bug_report_outlined,
                required: true,
                options: defectTypeLookupProvider,
                emptyMessage: 'No defect types set up. Ask an admin to add them in master data.',
                onChanged: _onType,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                inputFormatters: NumberInput.integer,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Quantity found', suffixText: 'pcs'),
                validator: Validators.positiveInt(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Severity', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: DefectListScreen.severities
                    .map((s) => ButtonSegment(value: s, label: Text(AppStatus.humanize(s))))
                    .toList(),
                selected: {_severity},
                onSelectionChanged: (s) => setState(() => _severity = s.first),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Log defect',
                icon: Icons.check_rounded,
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.of(context).pop(DefectDraft(
                    defectTypeId: _typeId!,
                    quantity: int.parse(_quantity.text.trim()),
                    severity: _severity,
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
