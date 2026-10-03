/// Mirrors backend TaMilestoneStatus (com.rmgflow.ta.entity.TaMilestoneStatus,
/// Doc 9.5) — DERIVED at read-time server-side, never stored/computed here.
enum TaMilestoneStatus {
  pending, upcoming, dueToday, overdue, criticalDelay, blocked, done;

  String get apiValue => switch (this) {
        TaMilestoneStatus.dueToday => 'DUE_TODAY',
        TaMilestoneStatus.criticalDelay => 'CRITICAL_DELAY',
        _ => name.toUpperCase(),
      };

  String get label => switch (this) {
        TaMilestoneStatus.dueToday => 'Due Today',
        TaMilestoneStatus.criticalDelay => 'Critical Delay',
        _ => name[0].toUpperCase() + name.substring(1),
      };

  static TaMilestoneStatus fromApiValue(String value) =>
      TaMilestoneStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend TaMilestoneResponse.
class TaMilestone {
  const TaMilestone({
    required this.id,
    required this.orderId,
    required this.milestoneTypeId,
    required this.milestoneTypeName,
    required this.sequence,
    required this.plannedDate,
    this.revisedDate,
    this.actualDate,
    this.responsibleUserId,
    this.responsibleFactoryId,
    required this.status,
    this.dependsOnMilestoneId,
    this.delayReason,
    required this.delayDays,
  });

  factory TaMilestone.fromJson(Map<String, dynamic> json) => TaMilestone(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        milestoneTypeId: json['milestoneTypeId'] as int,
        milestoneTypeName: json['milestoneTypeName'] as String,
        sequence: json['sequence'] as int,
        plannedDate: json['plannedDate'] as String,
        revisedDate: json['revisedDate'] as String?,
        actualDate: json['actualDate'] as String?,
        responsibleUserId: json['responsibleUserId'] as int?,
        responsibleFactoryId: json['responsibleFactoryId'] as int?,
        status: TaMilestoneStatus.fromApiValue(json['status'] as String),
        dependsOnMilestoneId: json['dependsOnMilestoneId'] as int?,
        delayReason: json['delayReason'] as String?,
        delayDays: json['delayDays'] as int,
      );

  final int id;
  final int orderId;
  final int milestoneTypeId;
  final String milestoneTypeName;
  final int sequence;
  final String plannedDate;
  final String? revisedDate;
  final String? actualDate;
  final int? responsibleUserId;
  final int? responsibleFactoryId;
  final TaMilestoneStatus status;
  final int? dependsOnMilestoneId;
  final String? delayReason;
  final int delayDays;

  /// Doc 9.5: the date that actually governs due-ness — revised if the
  /// delay-cascade (A16) pushed it, otherwise the original planned date.
  String get effectiveDate => revisedDate ?? plannedDate;
}

/// Mirrors backend RecordActualDateRequest.
class RecordActualDateDraft {
  const RecordActualDateDraft({required this.actualDate, this.delayReason});

  final String actualDate;
  final String? delayReason;

  Map<String, dynamic> toJson() => {
        'actualDate': actualDate,
        'delayReason': delayReason,
      };
}
