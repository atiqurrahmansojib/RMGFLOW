/// Mirrors backend ClaimRaisedBy.
enum ClaimRaisedBy {
  buyer, internal;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static ClaimRaisedBy fromApiValue(String value) =>
      ClaimRaisedBy.values.firstWhere((v) => v.apiValue == value);
}

/// Mirrors backend ClaimType.
enum ClaimType {
  shortShipment, quality, delay, other;

  String get apiValue => this == ClaimType.shortShipment ? 'SHORT_SHIPMENT' : name.toUpperCase();

  String get label => switch (this) {
        ClaimType.shortShipment => 'Short Shipment',
        _ => name[0].toUpperCase() + name.substring(1),
      };

  static ClaimType fromApiValue(String value) =>
      ClaimType.values.firstWhere((t) => t.apiValue == value);
}

/// Mirrors backend ClaimStatus.
enum ClaimStatus {
  open, underReview, resolved, rejected;

  String get apiValue => this == ClaimStatus.underReview ? 'UNDER_REVIEW' : name.toUpperCase();

  String get label => this == ClaimStatus.underReview ? 'Under Review' : name[0].toUpperCase() + name.substring(1);

  static ClaimStatus fromApiValue(String value) =>
      ClaimStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend ClaimResponse. Doc 6.3: ClaimService is deliberately
/// isolated — it never mutates Order/Shipment state, so a claim is purely
/// informational/tracking from this app's perspective.
class Claim {
  const Claim({
    required this.id,
    required this.orderId,
    this.shipmentId,
    required this.raisedBy,
    required this.claimType,
    required this.description,
    this.claimedAmount,
    required this.status,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Claim.fromJson(Map<String, dynamic> json) => Claim(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        shipmentId: json['shipmentId'] as int?,
        raisedBy: ClaimRaisedBy.fromApiValue(json['raisedBy'] as String),
        claimType: ClaimType.fromApiValue(json['claimType'] as String),
        description: json['description'] as String,
        claimedAmount: (json['claimedAmount'] as num?)?.toDouble(),
        status: ClaimStatus.fromApiValue(json['status'] as String),
        resolution: json['resolution'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      );

  final int id;
  final int orderId;
  final int? shipmentId;
  final ClaimRaisedBy raisedBy;
  final ClaimType claimType;
  final String description;
  final double? claimedAmount;
  final ClaimStatus status;
  final String? resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;
}

/// Mirrors backend ClaimRequest.
class ClaimDraft {
  const ClaimDraft({this.shipmentId, required this.raisedBy, required this.claimType, required this.description, this.claimedAmount});

  final int? shipmentId;
  final ClaimRaisedBy raisedBy;
  final ClaimType claimType;
  final String description;
  final double? claimedAmount;

  Map<String, dynamic> toJson() => {
        'shipmentId': shipmentId,
        'raisedBy': raisedBy.apiValue,
        'claimType': claimType.apiValue,
        'description': description,
        'claimedAmount': claimedAmount,
      };
}

/// Mirrors backend ClaimResolutionRequest.
class ClaimResolutionDraft {
  const ClaimResolutionDraft({required this.status, this.resolution});

  final ClaimStatus status;
  final String? resolution;

  Map<String, dynamic> toJson() => {
        'status': status.apiValue,
        'resolution': resolution,
      };
}
