import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/defect_controller.dart';
import '../domain/quality.dart';
import 'capa_list_screen.dart';

/// Document 7 (#60-61): defects logged against one inspection, with a
/// create-defect dialog and a link into that defect's CAPA records.
class DefectListScreen extends ConsumerWidget {
  const DefectListScreen({super.key, required this.inspection});

  final Inspection inspection;

  Future<void> _addDefect(BuildContext context, WidgetRef ref) async {
    final defectTypeIdController = TextEditingController();
    final quantityController = TextEditingController();
    final severityController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Defect'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: defectTypeIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Defect Type ID'),
            ),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(controller: severityController, decoration: const InputDecoration(labelText: 'Severity (e.g. MINOR/MAJOR/CRITICAL)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (confirmed != true) return;
    final defectTypeId = int.tryParse(defectTypeIdController.text.trim());
    final quantity = int.tryParse(quantityController.text.trim());
    if (defectTypeId == null || quantity == null || severityController.text.trim().isEmpty) return;
    await ref.read(defectFormControllerProvider.notifier).submit(
          inspection.id,
          DefectDraft(defectTypeId: defectTypeId, quantity: quantity, severity: severityController.text.trim().toUpperCase()),
        );
    ref.read(defectListControllerProvider(inspection.id).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(defectFormControllerProvider, (previous, next) {
      if (next is DefectFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final state = ref.watch(defectListControllerProvider(inspection.id));

    return Scaffold(
      appBar: AppBar(title: Text('${inspection.inspectionType.label} Defects')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDefect(context, ref),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        DefectListLoading() => const LoadingView(),
        DefectListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(defectListControllerProvider(inspection.id).notifier).refresh(),
          ),
        DefectListLoaded(:final defects) when defects.isEmpty =>
          const EmptyStateView(message: 'No defects logged for this inspection.', icon: Icons.bug_report_outlined),
        DefectListLoaded(:final defects) => RefreshIndicator(
            onRefresh: () => ref.read(defectListControllerProvider(inspection.id).notifier).refresh(),
            child: ListView.separated(
              itemCount: defects.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final defect = defects[index];
                return ListTile(
                  title: Text('Defect type #${defect.defectTypeId}'),
                  subtitle: Text('Qty ${defect.quantity} · Severity ${defect.severity}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CapaListScreen(defectId: defect.id)),
                  ),
                );
              },
            ),
          ),
      },
    );
  }
}
