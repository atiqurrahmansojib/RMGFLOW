/// Mirrors backend TaskPriority.
enum TaskPriority {
  low, medium, high, urgent;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static TaskPriority fromApiValue(String value) =>
      TaskPriority.values.firstWhere((p) => p.apiValue == value);
}

/// Mirrors backend TaskStatus.
enum TaskStatus {
  open, inProgress, done, cancelled;

  String get apiValue => this == TaskStatus.inProgress ? 'IN_PROGRESS' : name.toUpperCase();

  String get label => this == TaskStatus.inProgress ? 'In Progress' : name[0].toUpperCase() + name.substring(1);

  static TaskStatus fromApiValue(String value) =>
      TaskStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend TaskResponse. Doc 21: a task is ALWAYS attached to a real
/// business entity, never free-floating — `entityType`/`entityId` are required.
class TaskItem {
  const TaskItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.title,
    this.description,
    this.assignedToId,
    this.assignedToName,
    required this.priority,
    this.dueDate,
    required this.status,
    required this.overdue,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as int,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
        assignedToId: json['assignedToId'] as int?,
        assignedToName: json['assignedToName'] as String?,
        priority: TaskPriority.fromApiValue(json['priority'] as String),
        dueDate: json['dueDate'] as String?,
        status: TaskStatus.fromApiValue(json['status'] as String),
        overdue: json['overdue'] as bool,
      );

  final int id;
  final String entityType;
  final int entityId;
  final String title;
  final String? description;
  final int? assignedToId;
  final String? assignedToName;
  final TaskPriority priority;
  final String? dueDate;
  final TaskStatus status;
  final bool overdue;
}

/// Mirrors backend TaskRequest.
class TaskDraft {
  const TaskDraft({
    required this.entityType,
    required this.entityId,
    required this.title,
    this.description,
    this.assignedToId,
    required this.priority,
    this.dueDate,
  });

  final String entityType;
  final int entityId;
  final String title;
  final String? description;
  final int? assignedToId;
  final TaskPriority priority;
  final String? dueDate;

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'entityId': entityId,
        'title': title,
        'description': description,
        'assignedToId': assignedToId,
        'priority': priority.apiValue,
        'dueDate': dueDate,
      };
}
