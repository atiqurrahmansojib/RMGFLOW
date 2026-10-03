import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/task_item.dart';
import '../domain/task_repository.dart';

/// Document 11.2: talks to /api/v1/tasks — requires TASK_VIEW/TASK_MANAGE (Doc 5.2).
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<TaskItem>> listByEntity({required String entityType, required int entityId}) async {
    final response = await _dio.get('/tasks', queryParameters: {
      'entityType': entityType,
      'entityId': entityId,
    });
    return (response.data as List).map((e) => TaskItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TaskItem>> myOpenTasks() async {
    final response = await _dio.get('/tasks/my');
    return (response.data as List).map((e) => TaskItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<TaskItem> create(TaskDraft draft) async {
    final response = await _dio.post('/tasks', data: draft.toJson());
    return TaskItem.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TaskItem> updateStatus(int id, TaskStatus status) async {
    final response = await _dio.post('/tasks/$id/status', queryParameters: {'status': status.apiValue});
    return TaskItem.fromJson(response.data as Map<String, dynamic>);
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(apiDioProvider));
});
