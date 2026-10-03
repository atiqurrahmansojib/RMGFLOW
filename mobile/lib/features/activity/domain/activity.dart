/// Mirrors backend ActivityType.
enum ActivityType {
  call, email, meeting, note;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static ActivityType fromApiValue(String value) =>
      ActivityType.values.firstWhere((t) => t.apiValue == value);
}

/// Mirrors backend ActivityResponse — a generic (entityType, entityId) feed
/// reused across every module (Doc 8.9's polymorphic pattern), retroactive
/// logging supported via `occurredAt`.
class Activity {
  const Activity({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.activityType,
    required this.occurredAt,
    this.loggedById,
    required this.content,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as int,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as int,
        activityType: ActivityType.fromApiValue(json['activityType'] as String),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        loggedById: json['loggedById'] as int?,
        content: json['content'] as String,
      );

  final int id;
  final String entityType;
  final int entityId;
  final ActivityType activityType;
  final DateTime occurredAt;
  final int? loggedById;
  final String content;
}

/// Mirrors backend ActivityRequest.
class ActivityDraft {
  const ActivityDraft({
    required this.entityType,
    required this.entityId,
    required this.activityType,
    required this.occurredAt,
    required this.content,
  });

  final String entityType;
  final int entityId;
  final ActivityType activityType;
  final DateTime occurredAt;
  final String content;

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'entityId': entityId,
        'activityType': activityType.apiValue,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'content': content,
      };
}
