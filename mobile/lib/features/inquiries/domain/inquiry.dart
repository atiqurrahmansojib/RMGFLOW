/// Mirrors backend InquiryStatus (com.rmgflow.inquiry.entity.InquiryStatus, Doc 10.1).
enum InquiryStatus {
  open, quoted, won, lost, hold;

  String get apiValue => name.toUpperCase();

  String get label => switch (this) {
        InquiryStatus.open => 'Open',
        InquiryStatus.quoted => 'Quoted',
        InquiryStatus.won => 'Won',
        InquiryStatus.lost => 'Lost',
        InquiryStatus.hold => 'Hold',
      };

  static InquiryStatus fromApiValue(String value) =>
      InquiryStatus.values.firstWhere((s) => s.apiValue == value);
}

class Inquiry {
  const Inquiry({
    required this.id,
    required this.inquiryNo,
    required this.buyerId,
    required this.buyerName,
    this.seasonId,
    this.merchandiserId,
    this.targetQuantity,
    this.targetPrice,
    this.targetCurrency,
    this.deliveryRequirement,
    required this.status,
    this.lostReason,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) => Inquiry(
        id: json['id'] as int,
        inquiryNo: json['inquiryNo'] as String,
        buyerId: json['buyerId'] as int,
        buyerName: json['buyerName'] as String,
        seasonId: json['seasonId'] as int?,
        merchandiserId: json['merchandiserId'] as int?,
        targetQuantity: json['targetQuantity'] as int?,
        targetPrice: (json['targetPrice'] as num?)?.toDouble(),
        targetCurrency: json['targetCurrency'] as String?,
        deliveryRequirement: json['deliveryRequirement'] as String?,
        status: InquiryStatus.fromApiValue(json['status'] as String),
        lostReason: json['lostReason'] as String?,
      );

  final int id;
  final String inquiryNo;
  final int buyerId;
  final String buyerName;
  final int? seasonId;
  final int? merchandiserId;
  final int? targetQuantity;
  final double? targetPrice;
  final String? targetCurrency;
  final String? deliveryRequirement;
  final InquiryStatus status;
  final String? lostReason;
}

class InquiryDraft {
  const InquiryDraft({
    required this.inquiryNo,
    required this.buyerId,
    this.seasonId,
    this.merchandiserId,
    this.targetQuantity,
    this.targetPrice,
    this.targetCurrency,
    this.deliveryRequirement,
  });

  final String inquiryNo;
  final int buyerId;
  final int? seasonId;
  final int? merchandiserId;
  final int? targetQuantity;
  final double? targetPrice;
  final String? targetCurrency;
  final String? deliveryRequirement;

  Map<String, dynamic> toJson() => {
        'inquiryNo': inquiryNo,
        'buyerId': buyerId,
        'seasonId': seasonId,
        'merchandiserId': merchandiserId,
        'targetQuantity': targetQuantity,
        'targetPrice': targetPrice,
        'targetCurrency': targetCurrency,
        'deliveryRequirement': deliveryRequirement,
      };
}
