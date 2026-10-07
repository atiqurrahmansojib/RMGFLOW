import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/task_repository_impl.dart';
import '../domain/task_item.dart';

sealed class TaskListState {
  const TaskListState();
}

class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

class TaskListLoaded extends TaskListState {
  const TaskListLoaded(this.tasks);
  final List<TaskItem> tasks;
}

class TaskListError extends TaskListState {
  const TaskListError(this.failure);
  final Failure failure;
}

/// `null` target means "my open tasks" (Doc 7 #92); a target means tasks
/// attached to that specific entity.
final taskListControllerProvider =
    StateNotifierProvider.autoDispose.family<TaskListController, TaskListState, ({String entityType, int entityId})?>(
        (ref, target) {
  return TaskListController(ref, target)..load();
});

/// Document 7 (#92-93)/21: tasks are ALWAYS entity-attached (never
/// free-floating) — this controller serves both "my open tasks" and
/// "tasks for this entity" from the same repository method pair.
class TaskListController extends StateNotifier<TaskListState> {
  TaskListController(this._ref, this._target) : super(const TaskListLoading());

  final Ref _ref;
  final ({String entityType, int entityId})? _target;

  Future<void> load() async {
    state = const TaskListLoading();
    try {
      final repo = _ref.read(taskRepositoryProvider);
      final tasks = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _target == null
                ? repo.myOpenTasks()
                : repo.listByEntity(entityType: _target.entityType, entityId: _target.entityId),
          );
      state = TaskListLoaded(tasks);
    } on DioException catch (e) {
      state = TaskListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class TaskActionState {
  const TaskActionState();
}

class TaskActionIdle extends TaskActionState {
  const TaskActionIdle();
}

class TaskActionInProgress extends TaskActionState {
  const TaskActionInProgress();
}

class TaskActionSuccess extends TaskActionState {
  const TaskActionSuccess(this.task);
  final TaskItem task;
}

class TaskActionFailed extends TaskActionState {
  const TaskActionFailed(this.failure);
  final Failure failure;
}

final taskActionControllerProvider =
    StateNotifierProvider.autoDispose<TaskActionController, TaskActionState>((ref) {
  return TaskActionController(ref);
});

/// Document 7 (#93): create a task against an entity, change its status.
class TaskActionController extends StateNotifier<TaskActionState> {
  TaskActionController(this._ref) : super(const TaskActionIdle());

  final Ref _ref;

  Future<void> create(TaskDraft draft) async {
    state = const TaskActionInProgress();
    try {
      final task = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(taskRepositoryProvider).create(draft),
          );
      state = TaskActionSuccess(task);
    } on DioException catch (e) {
      state = TaskActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> updateStatus(int id, TaskStatus status) async {
    state = const TaskActionInProgress();
    try {
      final task = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(taskRepositoryProvider).updateStatus(id, status),
          );
      state = TaskActionSuccess(task);
    } on DioException catch (e) {
      state = TaskActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> reassign(int id, int? userId) async {
    state = const TaskActionInProgress();
    try {
      final task = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(taskRepositoryProvider).reassign(id, userId),
          );
      state = TaskActionSuccess(task);
    } on DioException catch (e) {
      state = TaskActionFailed(mapDioErrorToFailure(e));
    }
  }
}
