import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/activity.dart';
import '../domain/activity_repository.dart';

/// Document 11.2: talks to /api/v1/activities — requires ACTIVITY_VIEW/
/// ACTIVITY_MANAGE (Doc 5.2).
class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Activity>> list({required String entityType, required int entityId}) async {
    final response = await _dio.get('/activities', queryParameters: {
      'entityType': entityType,
      'entityId': entityId,
    });
    return (response.data as List).map((e) => Activity.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Activity> log(ActivityDraft draft) async {
    final response = await _dio.post('/activities', data: draft.toJson());
    return Activity.fromJson(response.data as Map<String, dynamic>);
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl(ref.watch(apiDioProvider));
});
