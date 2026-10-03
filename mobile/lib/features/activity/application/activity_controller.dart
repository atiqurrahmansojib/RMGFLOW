import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/activity_repository_impl.dart';
import '../domain/activity.dart';

typedef ActivityTarget = ({String entityType, int entityId});

sealed class ActivityListState {
  const ActivityListState();
}

class ActivityListLoading extends ActivityListState {
  const ActivityListLoading();
}

class ActivityListLoaded extends ActivityListState {
  const ActivityListLoaded(this.activities);
  final List<Activity> activities;
}

class ActivityListError extends ActivityListState {
  const ActivityListError(this.failure);
  final Failure failure;
}

final activityListControllerProvider =
    StateNotifierProvider.autoDispose.family<ActivityListController, ActivityListState, ActivityTarget>((ref, target) {
  return ActivityListController(ref, target)..load();
});

/// Document 7 (#89-91)/8.9: a communication/activity feed reused across every
/// module via a generic (entityType, entityId) key.
class ActivityListController extends StateNotifier<ActivityListState> {
  ActivityListController(this._ref, this._target) : super(const ActivityListLoading());

  final Ref _ref;
  final ActivityTarget _target;

  Future<void> load() async {
    state = const ActivityListLoading();
    try {
      final activities = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(activityRepositoryProvider).list(entityType: _target.entityType, entityId: _target.entityId),
          );
      state = ActivityListLoaded(activities);
    } on DioException catch (e) {
      state = ActivityListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class ActivityFormState {
  const ActivityFormState();
}

class ActivityFormIdle extends ActivityFormState {
  const ActivityFormIdle();
}

class ActivityFormSubmitting extends ActivityFormState {
  const ActivityFormSubmitting();
}

class ActivityFormSuccess extends ActivityFormState {
  const ActivityFormSuccess(this.activity);
  final Activity activity;
}

class ActivityFormFailed extends ActivityFormState {
  const ActivityFormFailed(this.failure);
  final Failure failure;
}

final activityFormControllerProvider =
    StateNotifierProvider.autoDispose<ActivityFormController, ActivityFormState>((ref) {
  return ActivityFormController(ref);
});

/// Document 7 (#90): log a call/email/meeting/note — `occurredAt` supports
/// retroactive logging (e.g. logging yesterday's call this morning).
class ActivityFormController extends StateNotifier<ActivityFormState> {
  ActivityFormController(this._ref) : super(const ActivityFormIdle());

  final Ref _ref;

  Future<void> submit(ActivityDraft draft) async {
    state = const ActivityFormSubmitting();
    try {
      final activity = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(activityRepositoryProvider).log(draft),
          );
      state = ActivityFormSuccess(activity);
    } on DioException catch (e) {
      state = ActivityFormFailed(mapDioErrorToFailure(e));
    }
  }
}
