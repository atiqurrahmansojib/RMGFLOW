/// Mirrors backend InspectionType.
enum InspectionType {
  inline, midline, final_;

  String get apiValue => this == InspectionType.final_ ? 'FINAL' : name.toUpperCase();

  String get label => switch (this) {
        InspectionType.inline => 'Inline',
        InspectionType.midline => 'Midline',
        InspectionType.final_ => 'Final',
      };

  static InspectionType fromApiValue(String value) =>
      InspectionType.values.firstWhere((t) => t.apiValue == value);
}

/// Mirrors backend InspectionResult — a FAIL/REINSPECT blocks shipment (Doc
/// 9.7/9.8's quality gate) unless overridden by a permitted user.
enum InspectionResult {
  pass, fail, reinspect;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static InspectionResult fromApiValue(String value) =>
      InspectionResult.values.firstWhere((r) => r.apiValue == value);
}

/// Mirrors backend InspectionResponse.
class Inspection {
  const Inspection({
    required this.id,
    required this.orderId,
    required this.inspectionType,
    required this.inspectionDate,
    required this.inspectedQty,
    this.aqlLevel,
    required this.result,
    this.inspectorId,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        inspectionType: InspectionType.fromApiValue(json['inspectionType'] as String),
        inspectionDate: json['inspectionDate'] as String,
        inspectedQty: json['inspectedQty'] as int,
        aqlLevel: json['aqlLevel'] as String?,
        result: InspectionResult.fromApiValue(json['result'] as String),
        inspectorId: json['inspectorId'] as int?,
      );

  final int id;
  final int orderId;
  final InspectionType inspectionType;
  final String inspectionDate;
  final int inspectedQty;
  final String? aqlLevel;
  final InspectionResult result;
  final int? inspectorId;
}

/// Mirrors backend InspectionRequest.
class InspectionDraft {
  const InspectionDraft({
    required this.inspectionType,
    required this.inspectionDate,
    required this.inspectedQty,
    this.aqlLevel,
    required this.result,
  });

  final InspectionType inspectionType;
  final String inspectionDate;
  final int inspectedQty;
  final String? aqlLevel;
  final InspectionResult result;

  Map<String, dynamic> toJson() => {
        'inspectionType': inspectionType.apiValue,
        'inspectionDate': inspectionDate,
        'inspectedQty': inspectedQty,
        'aqlLevel': aqlLevel,
        'result': result.apiValue,
      };
}

/// Mirrors backend DefectResponse.
class Defect {
  const Defect({
    required this.id,
    required this.inspectionId,
    required this.defectTypeId,
    required this.quantity,
    required this.severity,
    this.photoDocumentId,
  });

  factory Defect.fromJson(Map<String, dynamic> json) => Defect(
        id: json['id'] as int,
        inspectionId: json['inspectionId'] as int,
        defectTypeId: json['defectTypeId'] as int,
        quantity: json['quantity'] as int,
        severity: json['severity'] as String,
        photoDocumentId: json['photoDocumentId'] as int?,
      );

  final int id;
  final int inspectionId;
  final int defectTypeId;
  final int quantity;
  final String severity;
  final int? photoDocumentId;
}

/// Mirrors backend DefectRequest.
class DefectDraft {
  const DefectDraft({required this.defectTypeId, required this.quantity, required this.severity, this.photoDocumentId});

  final int defectTypeId;
  final int quantity;
  final String severity;
  final int? photoDocumentId;

  Map<String, dynamic> toJson() => {
        'defectTypeId': defectTypeId,
        'quantity': quantity,
        'severity': severity,
        'photoDocumentId': photoDocumentId,
      };
}

/// Mirrors backend CapaStatus.
enum CapaStatus {
  open, inProgress, closed;

  String get apiValue => this == CapaStatus.inProgress ? 'IN_PROGRESS' : name.toUpperCase();

  String get label => this == CapaStatus.inProgress ? 'In Progress' : name[0].toUpperCase() + name.substring(1);

  static CapaStatus fromApiValue(String value) =>
      CapaStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend CapaRecordResponse.
class CapaRecord {
  const CapaRecord({
    required this.id,
    this.defectId,
    this.inspectionId,
    required this.description,
    this.correctiveAction,
    this.preventiveAction,
    this.factoryResponse,
    required this.status,
    required this.createdAt,
    this.closedAt,
  });

  factory CapaRecord.fromJson(Map<String, dynamic> json) => CapaRecord(
        id: json['id'] as int,
        defectId: json['defectId'] as int?,
        inspectionId: json['inspectionId'] as int?,
        description: json['description'] as String,
        correctiveAction: json['correctiveAction'] as String?,
        preventiveAction: json['preventiveAction'] as String?,
        factoryResponse: json['factoryResponse'] as String?,
        status: CapaStatus.fromApiValue(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt'] as String) : null,
      );

  final int id;
  final int? defectId;
  final int? inspectionId;
  final String description;
  final String? correctiveAction;
  final String? preventiveAction;
  final String? factoryResponse;
  final CapaStatus status;
  final DateTime createdAt;
  final DateTime? closedAt;
}

/// Mirrors backend CapaRecordRequest.
class CapaRecordDraft {
  const CapaRecordDraft({
    this.defectId,
    this.inspectionId,
    required this.description,
    this.correctiveAction,
    this.preventiveAction,
  });

  final int? defectId;
  final int? inspectionId;
  final String description;
  final String? correctiveAction;
  final String? preventiveAction;

  Map<String, dynamic> toJson() => {
        'defectId': defectId,
        'inspectionId': inspectionId,
        'description': description,
        'correctiveAction': correctiveAction,
        'preventiveAction': preventiveAction,
      };
}
