import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/notification_repository_impl.dart';
import '../domain/notification.dart';

sealed class NotificationListState {
  const NotificationListState();
}

class NotificationListLoading extends NotificationListState {
  const NotificationListLoading();
}

class NotificationListLoaded extends NotificationListState {
  const NotificationListLoaded(this.notifications);
  final List<AppNotification> notifications;
}

class NotificationListError extends NotificationListState {
  const NotificationListError(this.failure);
  final Failure failure;
}

final notificationListControllerProvider =
    StateNotifierProvider.autoDispose<NotificationListController, NotificationListState>((ref) {
  return NotificationListController(ref)..load();
});

/// Document 7 (#88)/13: the in-app notification feed — the dispatch sink for
/// automation jobs like the T&A overdue scan (Doc A2).
class NotificationListController extends StateNotifier<NotificationListState> {
  NotificationListController(this._ref) : super(const NotificationListLoading());

  final Ref _ref;

  Future<void> load() async {
    state = const NotificationListLoading();
    try {
      final notifications = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(notificationRepositoryProvider).myNotifications(),
          );
      state = NotificationListLoaded(notifications);
    } on DioException catch (e) {
      state = NotificationListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> markRead(int id) async {
    await _ref.read(authControllerProvider.notifier).callAuthorized(
          () => _ref.read(notificationRepositoryProvider).markRead(id),
        );
    await load();
  }

  Future<void> refresh() => load();
}
