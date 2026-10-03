import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/task_controller.dart';
import '../domain/task_item.dart';

/// Document 7 (#92-93)/21: `target == null` shows "My Open Tasks" (reached
/// from HomeScreen); a non-null target shows tasks attached to that entity
/// (reached from a module's detail screen) — same screen, same repository.
class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key, this.target});

  final ({String entityType, int entityId})? target;

  Future<void> _createTask(BuildContext context, WidgetRef ref) async {
    if (target == null) return;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final assignedToController = TextEditingController();
    TaskPriority priority = TaskPriority.medium;
    DateTime? dueDate;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description (optional)')),
              TextField(controller: assignedToController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Assigned to (user ID, optional)')),
              DropdownButtonFormField<TaskPriority>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                onChanged: (v) => setState(() => priority = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (confirmed != true || titleController.text.trim().isEmpty) return;
    await ref.read(taskActionControllerProvider.notifier).create(
          TaskDraft(
            entityType: target!.entityType,
            entityId: target!.entityId,
            title: titleController.text.trim(),
            description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
            assignedToId: int.tryParse(assignedToController.text.trim()),
            priority: priority,
            dueDate: dueDate != null ? dueDate!.toIso8601String().split('T').first : null,
          ),
        );
    ref.read(taskListControllerProvider(target).notifier).refresh();
  }

  Color _priorityColor(TaskPriority priority) => switch (priority) {
        TaskPriority.urgent => Colors.red,
        TaskPriority.high => Colors.orange,
        TaskPriority.medium => Colors.blue,
        TaskPriority.low => Colors.grey,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(taskActionControllerProvider, (previous, next) {
      if (next is TaskActionFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final state = ref.watch(taskListControllerProvider(target));

    return Scaffold(
      appBar: AppBar(title: Text(target == null ? 'My Tasks' : 'Tasks')),
      floatingActionButton: target == null
          ? null
          : FloatingActionButton(onPressed: () => _createTask(context, ref), child: const Icon(Icons.add)),
      body: switch (state) {
        TaskListLoading() => const LoadingView(),
        TaskListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(taskListControllerProvider(target).notifier).refresh(),
          ),
        TaskListLoaded(:final tasks) when tasks.isEmpty =>
          const EmptyStateView(message: 'No tasks.', icon: Icons.task_outlined),
        TaskListLoaded(:final tasks) => RefreshIndicator(
            onRefresh: () => ref.read(taskListControllerProvider(target).notifier).refresh(),
            child: ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  leading: Icon(Icons.flag, color: _priorityColor(task.priority)),
                  title: Text(task.title, style: task.status == TaskStatus.done ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
                  subtitle: Text(
                    '${task.entityType} #${task.entityId}'
                    '${task.dueDate != null ? ' · Due ${task.dueDate}' : ''}'
                    '${task.overdue ? ' (OVERDUE)' : ''}',
                  ),
                  trailing: task.status == TaskStatus.done || task.status == TaskStatus.cancelled
                      ? Chip(label: Text(task.status.label))
                      : PopupMenuButton<TaskStatus>(
                          onSelected: (status) async {
                            await ref.read(taskActionControllerProvider.notifier).updateStatus(task.id, status);
                            ref.read(taskListControllerProvider(target).notifier).refresh();
                          },
                          itemBuilder: (context) => [TaskStatus.inProgress, TaskStatus.done, TaskStatus.cancelled]
                              .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                              .toList(),
                          child: Chip(label: Text(task.status.label)),
                        ),
                );
              },
            ),
          ),
      },
    );
  }
}
