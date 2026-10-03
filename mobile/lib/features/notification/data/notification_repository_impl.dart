import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/notification.dart';
import '../domain/notification_repository.dart';

/// Document 11.2: talks to /api/v1/notifications — no permission gate beyond
/// authentication (a notification is inherently personal to the logged-in
/// user; the backend scopes every query to the caller's own id).
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<AppNotification>> myNotifications() async {
    final response = await _dio.get('/notifications');
    return (response.data as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> markRead(int id) async {
    await _dio.post('/notifications/$id/read');
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(apiDioProvider));
});
