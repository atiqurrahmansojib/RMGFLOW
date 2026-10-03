import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/ta_milestone_controller.dart';
import '../domain/ta_milestone.dart';

/// Document 7 (#54-58): one order's T&A calendar. Status chips reflect the
/// server-derived status (Doc 9.5) — DONE/BLOCKED/CRITICAL_DELAY/OVERDUE/
/// DUE_TODAY/UPCOMING/PENDING — never recomputed on-device.
class TaMilestoneListScreen extends ConsumerWidget {
  const TaMilestoneListScreen({super.key, required this.orderId, required this.styleId});

  final int orderId;
  final int styleId;

  Color _statusColor(BuildContext context, TaMilestoneStatus status) => switch (status) {
        TaMilestoneStatus.done => Colors.green,
        TaMilestoneStatus.criticalDelay => Colors.red,
        TaMilestoneStatus.overdue => Colors.orange,
        TaMilestoneStatus.blocked => Colors.grey,
        TaMilestoneStatus.dueToday => Colors.amber,
        _ => Theme.of(context).colorScheme.primary,
      };

  Future<void> _recordActualDate(BuildContext context, WidgetRef ref, TaMilestone milestone) async {
    final reasonController = TextEditingController();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final isLate = date.isAfter(DateTime.parse(milestone.effectiveDate));
    if (isLate && context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delay reason required'),
          content: TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason')),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
          ],
        ),
      );
      if (confirmed != true || reasonController.text.trim().isEmpty) return;
    }
    final draft = RecordActualDateDraft(
      actualDate: date.toIso8601String().split('T').first,
      delayReason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
    );
    await ref.read(taMilestoneActionControllerProvider.notifier).recordActualDate(orderId, milestone.id, draft);
    ref.read(taMilestoneListControllerProvider(orderId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(taMilestoneActionControllerProvider, (previous, next) {
      if (next is TaMilestoneActionFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final state = ref.watch(taMilestoneListControllerProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('T&A Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Generate from template',
            onPressed: () => ref.read(taMilestoneListControllerProvider(orderId).notifier).generate(styleId),
          ),
        ],
      ),
      body: switch (state) {
        TaMilestoneListLoading() => const LoadingView(),
        TaMilestoneListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(taMilestoneListControllerProvider(orderId).notifier).refresh(),
          ),
        TaMilestoneListLoaded(:final milestones) when milestones.isEmpty => EmptyStateView(
            message: 'No T&A milestones yet. Tap refresh to generate from the style\'s template.',
            icon: Icons.event_note_outlined,
          ),
        TaMilestoneListLoaded(:final milestones) => RefreshIndicator(
            onRefresh: () => ref.read(taMilestoneListControllerProvider(orderId).notifier).refresh(),
            child: ListView.separated(
              itemCount: milestones.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final milestone = milestones[index];
                return ListTile(
                  title: Text('${milestone.sequence}. ${milestone.milestoneTypeName}'),
                  subtitle: Text(
                    'Planned: ${milestone.plannedDate}'
                    '${milestone.revisedDate != null ? ' · Revised: ${milestone.revisedDate}' : ''}'
                    '${milestone.actualDate != null ? ' · Actual: ${milestone.actualDate}' : ''}'
                    '${milestone.delayReason != null ? '\nDelay: ${milestone.delayReason}' : ''}',
                  ),
                  isThreeLine: milestone.delayReason != null,
                  trailing: Chip(
                    label: Text(milestone.status.label),
                    backgroundColor: _statusColor(context, milestone.status).withOpacity(0.15),
                  ),
                  onTap: milestone.actualDate != null ? null : () => _recordActualDate(context, ref, milestone),
                );
              },
            ),
          ),
      },
    );
  }
}
