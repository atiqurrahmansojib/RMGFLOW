/// Mirrors backend DocumentEntityType — the polymorphic target this document
/// is attached to (Doc 8.9: reuses the generic Attachment module, never a
/// duplicated storage path).
enum DocumentEntityType {
  order, shipment, factory, style;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static DocumentEntityType fromApiValue(String value) =>
      DocumentEntityType.values.firstWhere((t) => t.apiValue == value);
}

/// Mirrors backend DocumentStatus.
enum DocumentStatus {
  draft, submitted, approved, expired;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static DocumentStatus fromApiValue(String value) =>
      DocumentStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend CommercialDocumentResponse.
class CommercialDocument {
  const CommercialDocument({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.documentTypeId,
    required this.versionNo,
    required this.fileAttachmentId,
    required this.status,
    this.ownerId,
    required this.uploadedAt,
    this.expiryDate,
    required this.expired,
  });

  factory CommercialDocument.fromJson(Map<String, dynamic> json) => CommercialDocument(
        id: json['id'] as int,
        entityType: DocumentEntityType.fromApiValue(json['entityType'] as String),
        entityId: json['entityId'] as int,
        documentTypeId: json['documentTypeId'] as int,
        versionNo: json['versionNo'] as int,
        fileAttachmentId: json['fileAttachmentId'] as int,
        status: DocumentStatus.fromApiValue(json['status'] as String),
        ownerId: json['ownerId'] as int?,
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
        expiryDate: json['expiryDate'] as String?,
        expired: json['expired'] as bool,
      );

  final int id;
  final DocumentEntityType entityType;
  final int entityId;
  final int documentTypeId;
  final int versionNo;
  final int fileAttachmentId;
  final DocumentStatus status;
  final int? ownerId;
  final DateTime uploadedAt;
  final String? expiryDate;
  final bool expired;
}

/// Mirrors backend CommercialDocumentRequest. `fileAttachmentId` references an
/// already-uploaded Attachment (Doc 8.9) — this app has no attachment-upload
/// screen yet (tracked in mobile/README.md), so it's entered as a raw numeric
/// ID same as every other cross-module reference so far.
class CommercialDocumentDraft {
  const CommercialDocumentDraft({
    required this.entityType,
    required this.entityId,
    required this.documentTypeId,
    required this.fileAttachmentId,
    this.expiryDate,
  });

  final DocumentEntityType entityType;
  final int entityId;
  final int documentTypeId;
  final int fileAttachmentId;
  final String? expiryDate;

  Map<String, dynamic> toJson() => {
        'entityType': entityType.apiValue,
        'entityId': entityId,
        'documentTypeId': documentTypeId,
        'fileAttachmentId': fileAttachmentId,
        'expiryDate': expiryDate,
      };
}
