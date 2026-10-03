/// Mirrors backend ApprovalTargetType (com.rmgflow.approval.entity.ApprovalTargetType,
/// Doc 8.4/ADR-08) — every gate the shared Approval Engine covers.
enum ApprovalTargetType {
  costing, quotation, sampleRevision, labDip, trim, ppSample, inspection, shipment, document;

  String get apiValue => switch (this) {
        ApprovalTargetType.sampleRevision => 'SAMPLE_REVISION',
        ApprovalTargetType.labDip => 'LAB_DIP',
        ApprovalTargetType.ppSample => 'PP_SAMPLE',
        _ => name.toUpperCase(),
      };

  String get label => switch (this) {
        ApprovalTargetType.costing => 'Costing',
        ApprovalTargetType.quotation => 'Quotation',
        ApprovalTargetType.sampleRevision => 'Sample Revision',
        ApprovalTargetType.labDip => 'Lab Dip',
        ApprovalTargetType.trim => 'Trim',
        ApprovalTargetType.ppSample => 'PP Sample',
        ApprovalTargetType.inspection => 'Inspection',
        ApprovalTargetType.shipment => 'Shipment',
        ApprovalTargetType.document => 'Document',
      };

  static ApprovalTargetType fromApiValue(String value) =>
      ApprovalTargetType.values.firstWhere((t) => t.apiValue == value);
}

/// Mirrors backend ApprovalStatus (Doc 8.4/FR-111) — history is append-only,
/// a new round rather than an edit to a decided one (DB-trigger-enforced).
enum ApprovalStatus {
  submitted, pending, approved, rejected, returned, resubmitted, withdrawn;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static ApprovalStatus fromApiValue(String value) =>
      ApprovalStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend ApprovalResponse.
class Approval {
  const Approval({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.roundNo,
    required this.status,
    this.submittedById,
    this.submittedAt,
    this.decidedById,
    this.decidedAt,
    this.comments,
    this.rejectionReason,
  });

  factory Approval.fromJson(Map<String, dynamic> json) => Approval(
        id: json['id'] as int,
        targetType: ApprovalTargetType.fromApiValue(json['targetType'] as String),
        targetId: json['targetId'] as int,
        roundNo: json['roundNo'] as int,
        status: ApprovalStatus.fromApiValue(json['status'] as String),
        submittedById: json['submittedById'] as int?,
        submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt'] as String) : null,
        decidedById: json['decidedById'] as int?,
        decidedAt: json['decidedAt'] != null ? DateTime.parse(json['decidedAt'] as String) : null,
        comments: json['comments'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
      );

  final int id;
  final ApprovalTargetType targetType;
  final int targetId;
  final int roundNo;
  final ApprovalStatus status;
  final int? submittedById;
  final DateTime? submittedAt;
  final int? decidedById;
  final DateTime? decidedAt;
  final String? comments;
  final String? rejectionReason;
}

/// Mirrors backend ApprovalDecisionRequest.
class ApprovalDecision {
  const ApprovalDecision({required this.decision, this.comments, this.rejectionReason});

  final ApprovalStatus decision;
  final String? comments;
  final String? rejectionReason;

  Map<String, dynamic> toJson() => {
        'decision': decision.apiValue,
        'comments': comments,
        'rejectionReason': rejectionReason,
      };
}
