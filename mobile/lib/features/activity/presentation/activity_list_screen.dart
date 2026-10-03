import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/activity_controller.dart';
import '../domain/activity.dart';

/// Document 7 (#89-91)/8.9: generic communication/activity log, reused for
/// any entity type by passing a different `entityType`/`entityId`.
class ActivityListScreen extends ConsumerWidget {
  const ActivityListScreen({super.key, required this.entityType, required this.entityId});

  final String entityType;
  final int entityId;

  Future<void> _logActivity(BuildContext context, WidgetRef ref) async {
    final contentController = TextEditingController();
    DateTime occurredAt = DateTime.now();
    ActivityType activityType = ActivityType.note;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Log Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ActivityType>(
                value: activityType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ActivityType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) => setState(() => activityType = v!),
              ),
              TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (confirmed != true || contentController.text.trim().isEmpty) return;
    await ref.read(activityFormControllerProvider.notifier).submit(
          ActivityDraft(
            entityType: entityType,
            entityId: entityId,
            activityType: activityType,
            occurredAt: occurredAt,
            content: contentController.text.trim(),
          ),
        );
    ref.read(activityListControllerProvider((entityType: entityType, entityId: entityId)).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(activityFormControllerProvider, (previous, next) {
      if (next is ActivityFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final target = (entityType: entityType, entityId: entityId);
    final state = ref.watch(activityListControllerProvider(target));

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Log')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _logActivity(context, ref),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        ActivityListLoading() => const LoadingView(),
        ActivityListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(activityListControllerProvider(target).notifier).refresh(),
          ),
        ActivityListLoaded(:final activities) when activities.isEmpty =>
          const EmptyStateView(message: 'No activity logged yet.', icon: Icons.history_edu_outlined),
        ActivityListLoaded(:final activities) => RefreshIndicator(
            onRefresh: () => ref.read(activityListControllerProvider(target).notifier).refresh(),
            child: ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(activity.activityType.label[0])),
                  title: Text(activity.content),
                  subtitle: Text('${activity.activityType.label} · ${activity.occurredAt}'),
                );
              },
            ),
          ),
      },
    );
  }
}
