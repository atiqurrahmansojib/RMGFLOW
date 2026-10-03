import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/capa_controller.dart';
import '../domain/quality.dart';

/// Document 7 (#63-64)/9.9: CAPA records for one defect — create, record a
/// factory response, and close the full corrective/preventive action loop.
class CapaListScreen extends ConsumerWidget {
  const CapaListScreen({super.key, required this.defectId});

  final int defectId;

  Future<void> _createCapa(BuildContext context, WidgetRef ref) async {
    final descriptionController = TextEditingController();
    final correctiveController = TextEditingController();
    final preventiveController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New CAPA Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: correctiveController, decoration: const InputDecoration(labelText: 'Corrective action (optional)')),
            TextField(controller: preventiveController, decoration: const InputDecoration(labelText: 'Preventive action (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Create')),
        ],
      ),
    );
    if (confirmed != true || descriptionController.text.trim().isEmpty) return;
    await ref.read(capaActionControllerProvider.notifier).create(
          CapaRecordDraft(
            defectId: defectId,
            description: descriptionController.text.trim(),
            correctiveAction: correctiveController.text.trim().isEmpty ? null : correctiveController.text.trim(),
            preventiveAction: preventiveController.text.trim().isEmpty ? null : preventiveController.text.trim(),
          ),
        );
    ref.read(capaListByDefectControllerProvider(defectId).notifier).refresh();
  }

  Future<void> _recordFactoryResponse(BuildContext context, WidgetRef ref, int capaId) async {
    final responseController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Factory Response'),
        content: TextField(controller: responseController, decoration: const InputDecoration(labelText: 'Response'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (confirmed != true || responseController.text.trim().isEmpty) return;
    await ref.read(capaActionControllerProvider.notifier).recordFactoryResponse(capaId, responseController.text.trim());
    ref.read(capaListByDefectControllerProvider(defectId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(capaActionControllerProvider, (previous, next) {
      if (next is CapaActionFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final state = ref.watch(capaListByDefectControllerProvider(defectId));

    return Scaffold(
      appBar: AppBar(title: const Text('CAPA Records')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createCapa(context, ref),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        CapaListLoading() => const LoadingView(),
        CapaListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(capaListByDefectControllerProvider(defectId).notifier).refresh(),
          ),
        CapaListLoaded(:final records) when records.isEmpty =>
          const EmptyStateView(message: 'No CAPA records yet.', icon: Icons.build_circle_outlined),
        CapaListLoaded(:final records) => RefreshIndicator(
            onRefresh: () => ref.read(capaListByDefectControllerProvider(defectId).notifier).refresh(),
            child: ListView.separated(
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = records[index];
                return ListTile(
                  title: Text(record.description),
                  subtitle: Text([
                    if (record.correctiveAction != null) 'Corrective: ${record.correctiveAction}',
                    if (record.preventiveAction != null) 'Preventive: ${record.preventiveAction}',
                    if (record.factoryResponse != null) 'Factory: ${record.factoryResponse}',
                  ].join('\n')),
                  isThreeLine: true,
                  trailing: record.status == CapaStatus.closed
                      ? Chip(label: Text(record.status.label))
                      : PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'respond') {
                              await _recordFactoryResponse(context, ref, record.id);
                            } else if (value == 'close') {
                              await ref.read(capaActionControllerProvider.notifier).close(record.id);
                              ref.read(capaListByDefectControllerProvider(defectId).notifier).refresh();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'respond', child: Text('Record factory response')),
                            const PopupMenuItem(value: 'close', child: Text('Close')),
                          ],
                        ),
                );
              },
            ),
          ),
      },
    );
  }
}
