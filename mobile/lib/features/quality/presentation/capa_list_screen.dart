import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../application/capa_controller.dart';
import '../domain/quality.dart';

/// Document 7 (#63-64)/9.9: CAPA records for one defect — create, record a
/// factory response, and close the full corrective/preventive action loop.
class CapaListScreen extends ConsumerWidget {
  const CapaListScreen({super.key, required this.defectId});

  final int defectId;

  Future<void> _createCapa(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<CapaRecordDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _CapaSheet(defectId: defectId),
    );
    if (draft == null) return;
    await ref.read(capaActionControllerProvider.notifier).create(draft);
    if (context.mounted && ref.read(capaActionControllerProvider) is CapaActionSuccess) {
      showSuccessSnack(context, 'CAPA record created');
    }
    ref.read(capaListByDefectControllerProvider(defectId).notifier).refresh();
  }

  Future<void> _recordFactoryResponse(BuildContext context, WidgetRef ref, int capaId) async {
    final response = await promptForReason(
      context,
      title: 'Factory response',
      message: "Record what the factory says it has done or will do.",
      label: 'Response',
      confirmLabel: 'Save response',
    );
    if (response == null) return;
    await ref.read(capaActionControllerProvider.notifier).recordFactoryResponse(capaId, response);
    if (context.mounted && ref.read(capaActionControllerProvider) is CapaActionSuccess) {
      showSuccessSnack(context, 'Factory response saved');
    }
    ref.read(capaListByDefectControllerProvider(defectId).notifier).refresh();
  }

  Future<void> _close(BuildContext context, WidgetRef ref, CapaRecord record) async {
    final ok = await confirmAction(
      context,
      title: 'Close this CAPA?',
      message: record.factoryResponse == null
          ? 'No factory response has been recorded yet. Closing confirms the corrective and preventive actions are done. '
              'A closed CAPA cannot be reopened.'
          : 'Closing confirms the corrective and preventive actions are done. A closed CAPA cannot be reopened.',
      confirmLabel: 'Close CAPA',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(capaActionControllerProvider.notifier).close(record.id);
    if (context.mounted && ref.read(capaActionControllerProvider) is CapaActionSuccess) {
      showSuccessSnack(context, 'CAPA closed');
    }
    ref.read(capaListByDefectControllerProvider(defectId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(capaActionControllerProvider, (previous, next) {
      if (next is CapaActionFailed) showErrorSnack(context, next.failure.message);
    });
    final state = ref.watch(capaListByDefectControllerProvider(defectId));

    return Scaffold(
      appBar: AppBar(title: const Text('CAPA Records')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCapa(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New CAPA'),
      ),
      body: switch (state) {
        CapaListLoading() => const LoadingView(),
        CapaListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(capaListByDefectControllerProvider(defectId).notifier).refresh(),
          ),
        CapaListLoaded(:final records) when records.isEmpty => EmptyStateView(
            title: 'No CAPA yet',
            message: 'Create a Corrective And Preventive Action so this defect does not happen again.',
            icon: Icons.build_circle_outlined,
            color: AppModules.quality.color,
            actionLabel: 'New CAPA',
            onAction: () => _createCapa(context, ref),
          ),
        CapaListLoaded(:final records) => RefreshIndicator(
            onRefresh: () => ref.read(capaListByDefectControllerProvider(defectId).notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.listWithFab,
              children: records.map((record) {
                final closed = record.status == CapaStatus.closed;
                void actions() => showQuickActions(
                      context,
                      title: record.description,
                      actions: [
                        QuickAction(
                          icon: Icons.reply_rounded,
                          label: 'Record factory response',
                          color: AppModules.factories.color,
                          onTap: () => _recordFactoryResponse(context, ref, record.id),
                        ),
                        QuickAction(
                          icon: Icons.lock_outline_rounded,
                          label: 'Close CAPA',
                          color: AppColors.success,
                          onTap: () => _close(context, ref, record),
                        ),
                      ],
                    );
                return AppCard(
                  accentColor: AppStatus.color(record.status.apiValue),
                  onLongPress: closed ? null : actions,
                  child: RecordRow(
                    leading: IconBadge(icon: Icons.build_circle_rounded, color: AppModules.quality.color),
                    title: record.description,
                    subtitle: 'Opened ${displayDateFormat.format(record.createdAt.toLocal())}'
                        '${record.closedAt != null ? ' · closed ${displayDateFormat.format(record.closedAt!.toLocal())}' : ''}',
                    trailing: StatusChip(record.status.apiValue, label: record.status.label, dense: true),
                    footer: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InfoRow(label: 'Corrective action', value: record.correctiveAction, vertical: true),
                        InfoRow(label: 'Preventive action', value: record.preventiveAction, vertical: true),
                        InfoRow(label: 'Factory response', value: record.factoryResponse, vertical: true),
                        if (!closed) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.reply_rounded),
                                  label: const Text('Response'),
                                  onPressed: () => _recordFactoryResponse(context, ref, record.id),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: PrimaryButton(
                                  icon: Icons.lock_outline_rounded,
                                  label: 'Close',
                                  variant: ButtonVariant.tonal,
                                  onPressed: () => _close(context, ref, record),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      },
    );
  }
}

class _CapaSheet extends StatefulWidget {
  const _CapaSheet({required this.defectId});
  final int defectId;

  @override
  State<_CapaSheet> createState() => _CapaSheetState();
}

class _CapaSheetState extends State<_CapaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _corrective = TextEditingController();
  final _preventive = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    _corrective.dispose();
    _preventive.dispose();
    super.dispose();
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
              Text('New CAPA record', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Problem description', hintText: 'e.g. Broken stitch at side seam'),
                validator: Validators.required('Description'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _corrective,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Corrective action (optional)', hintText: 'Fix for the current goods'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _preventive,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Preventive action (optional)', hintText: 'Stop it happening again'),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Create CAPA',
                icon: Icons.check_rounded,
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.of(context).pop(CapaRecordDraft(
                    defectId: widget.defectId,
                    description: _description.text.trim(),
                    correctiveAction: blankToNull(_corrective.text),
                    preventiveAction: blankToNull(_preventive.text),
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
