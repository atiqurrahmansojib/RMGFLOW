import 'notification.dart';

/// Document 12.2: domain contract for /api/v1/notifications (Doc 8.9/13).
abstract class NotificationRepository {
  Future<List<AppNotification>> myNotifications();
  Future<void> markRead(int id);
}
