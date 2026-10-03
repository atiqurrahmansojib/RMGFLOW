/// Mirrors backend SampleStatus (com.rmgflow.sample.entity.SampleStatus, Doc 8.4)
/// — a DERIVED rollup of the latest revision's approval decision, never itself
/// the source of truth (kept in sync via POST .../revisions/sync-status).
enum SampleStatus {
  requested, submitted, approved, rejected, returned;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static SampleStatus fromApiValue(String value) =>
      SampleStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend SampleResponse.
class Sample {
  const Sample({
    required this.id,
    required this.sampleNo,
    required this.styleId,
    required this.buyerId,
    this.factoryId,
    required this.sampleTypeId,
    required this.requestDate,
    this.requiredDate,
    required this.currentStatus,
  });

  factory Sample.fromJson(Map<String, dynamic> json) => Sample(
        id: json['id'] as int,
        sampleNo: json['sampleNo'] as String,
        styleId: json['styleId'] as int,
        buyerId: json['buyerId'] as int,
        factoryId: json['factoryId'] as int?,
        sampleTypeId: json['sampleTypeId'] as int,
        requestDate: json['requestDate'] as String,
        requiredDate: json['requiredDate'] as String?,
        currentStatus: SampleStatus.fromApiValue(json['currentStatus'] as String),
      );

  final int id;
  final String sampleNo;
  final int styleId;
  final int buyerId;
  final int? factoryId;
  final int sampleTypeId;
  final String requestDate;
  final String? requiredDate;
  final SampleStatus currentStatus;
}

/// Mirrors backend SampleRequest.
class SampleDraft {
  const SampleDraft({
    required this.styleId,
    required this.buyerId,
    this.factoryId,
    required this.sampleTypeId,
    required this.requestDate,
    this.requiredDate,
  });

  final int styleId;
  final int buyerId;
  final int? factoryId;
  final int sampleTypeId;
  final String requestDate;
  final String? requiredDate;

  Map<String, dynamic> toJson() => {
        'styleId': styleId,
        'buyerId': buyerId,
        'factoryId': factoryId,
        'sampleTypeId': sampleTypeId,
        'requestDate': requestDate,
        'requiredDate': requiredDate,
      };
}

/// Mirrors backend SampleRevisionResponse (Doc 9.3: append-only, no update endpoint).
class SampleRevision {
  const SampleRevision({
    required this.id,
    required this.sampleId,
    required this.revisionNo,
    this.submittedDate,
    this.comments,
    required this.createdAt,
  });

  factory SampleRevision.fromJson(Map<String, dynamic> json) => SampleRevision(
        id: json['id'] as int,
        sampleId: json['sampleId'] as int,
        revisionNo: json['revisionNo'] as int,
        submittedDate: json['submittedDate'] as String?,
        comments: json['comments'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final int id;
  final int sampleId;
  final int revisionNo;
  final String? submittedDate;
  final String? comments;
  final DateTime createdAt;
}

/// Mirrors backend SampleRevisionRequest.
class SampleRevisionDraft {
  const SampleRevisionDraft({this.submittedDate, this.comments});

  final String? submittedDate;
  final String? comments;

  Map<String, dynamic> toJson() => {
        'submittedDate': submittedDate,
        'comments': comments,
      };
}
