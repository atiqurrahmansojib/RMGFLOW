import 'activity.dart';

/// Document 12.2: domain contract for /api/v1/activities (Doc 8.9) — generic
/// across every (entityType, entityId).
abstract class ActivityRepository {
  Future<List<Activity>> list({required String entityType, required int entityId});
  Future<Activity> log(ActivityDraft draft);
}
