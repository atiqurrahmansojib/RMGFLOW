import 'task_item.dart';

/// Document 12.2: domain contract for /api/v1/tasks (Doc 21).
abstract class TaskRepository {
  Future<List<TaskItem>> listByEntity({required String entityType, required int entityId});
  Future<List<TaskItem>> myOpenTasks();
  Future<TaskItem> create(TaskDraft draft);
  Future<TaskItem> updateStatus(int id, TaskStatus status);
}
