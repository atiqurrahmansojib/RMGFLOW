/// Mirrors backend NotificationResponse — scoped to the current user server-side.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as int,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as int,
        message: json['message'] as String,
        read: json['read'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final int id;
  final String entityType;
  final int entityId;
  final String message;
  final bool read;
  final DateTime createdAt;
}
