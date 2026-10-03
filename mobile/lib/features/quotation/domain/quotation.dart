/// Mirrors backend QuotationStatus (com.rmgflow.quotation.entity.QuotationStatus).
enum QuotationStatus {
  draft, sent, negotiating, approved, rejected, expired, superseded;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static QuotationStatus fromApiValue(String value) =>
      QuotationStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend QuotationResponse.
class Quotation {
  const Quotation({
    required this.id,
    required this.costingId,
    this.quotationNo,
    required this.versionNo,
    required this.buyerId,
    required this.styleId,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
    this.incoterm,
    this.paymentTermsId,
    this.validityDate,
    this.leadTimeDays,
    required this.status,
    this.supersedesQuotationId,
    required this.version,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) => Quotation(
        id: json['id'] as int,
        costingId: json['costingId'] as int,
        quotationNo: json['quotationNo'] as String?,
        versionNo: json['versionNo'] as int,
        buyerId: json['buyerId'] as int,
        styleId: json['styleId'] as int,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        currency: json['currency'] as String,
        incoterm: json['incoterm'] as String?,
        paymentTermsId: json['paymentTermsId'] as int?,
        validityDate: json['validityDate'] as String?,
        leadTimeDays: json['leadTimeDays'] as int?,
        status: QuotationStatus.fromApiValue(json['status'] as String),
        supersedesQuotationId: json['supersedesQuotationId'] as int?,
        version: json['version'] as int,
      );

  final int id;
  final int costingId;
  final String? quotationNo;
  final int versionNo;
  final int buyerId;
  final int styleId;
  final int quantity;
  final double unitPrice;
  final String currency;
  final String? incoterm;
  final int? paymentTermsId;
  final String? validityDate;
  final int? leadTimeDays;
  final QuotationStatus status;
  final int? supersedesQuotationId;
  final int version;
}

/// Mirrors backend QuotationRequest.
class QuotationDraft {
  const QuotationDraft({
    required this.costingId,
    this.quotationNo,
    required this.buyerId,
    required this.styleId,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
    this.incoterm,
    this.paymentTermsId,
    this.validityDate,
    this.leadTimeDays,
  });

  final int costingId;
  final String? quotationNo;
  final int buyerId;
  final int styleId;
  final int quantity;
  final double unitPrice;
  final String currency;
  final String? incoterm;
  final int? paymentTermsId;
  final String? validityDate;
  final int? leadTimeDays;

  Map<String, dynamic> toJson() => {
        'costingId': costingId,
        'quotationNo': quotationNo,
        'buyerId': buyerId,
        'styleId': styleId,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'currency': currency,
        'incoterm': incoterm,
        'paymentTermsId': paymentTermsId,
        'validityDate': validityDate,
        'leadTimeDays': leadTimeDays,
      };
}
