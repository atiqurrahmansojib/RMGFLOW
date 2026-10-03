/// Mirrors backend OrderFinancialsResponse (Doc 9.10) — margin is ALWAYS
/// server-computed, using realizedUnitPrice when set, else falling back to
/// quotedUnitPrice (isEstimate flags which basis was used).
class OrderFinancials {
  const OrderFinancials({
    required this.id,
    required this.orderId,
    this.quotedUnitPrice,
    this.actualCostUnit,
    this.realizedUnitPrice,
    this.operationalMarginPercent,
    required this.isEstimate,
  });

  factory OrderFinancials.fromJson(Map<String, dynamic> json) => OrderFinancials(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        quotedUnitPrice: (json['quotedUnitPrice'] as num?)?.toDouble(),
        actualCostUnit: (json['actualCostUnit'] as num?)?.toDouble(),
        realizedUnitPrice: (json['realizedUnitPrice'] as num?)?.toDouble(),
        operationalMarginPercent: (json['operationalMarginPercent'] as num?)?.toDouble(),
        isEstimate: json['isEstimate'] as bool,
      );

  final int id;
  final int orderId;
  final double? quotedUnitPrice;
  final double? actualCostUnit;
  final double? realizedUnitPrice;
  final double? operationalMarginPercent;
  final bool isEstimate;
}

/// Mirrors backend OrderFinancialsRequest.
class OrderFinancialsDraft {
  const OrderFinancialsDraft({this.quotedUnitPrice, this.actualCostUnit, this.realizedUnitPrice});

  final double? quotedUnitPrice;
  final double? actualCostUnit;
  final double? realizedUnitPrice;

  Map<String, dynamic> toJson() => {
        'quotedUnitPrice': quotedUnitPrice,
        'actualCostUnit': actualCostUnit,
        'realizedUnitPrice': realizedUnitPrice,
      };
}

/// Mirrors backend ReceivableResponse — `status` (PENDING/PARTIAL/RECEIVED/
/// OVERDUE) is a DERIVED string from the server, never computed here.
class Receivable {
  const Receivable({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.receivedAmount,
    required this.status,
  });

  factory Receivable.fromJson(Map<String, dynamic> json) => Receivable(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        buyerId: json['buyerId'] as int,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        dueDate: json['dueDate'] as String,
        receivedAmount: (json['receivedAmount'] as num).toDouble(),
        status: json['status'] as String,
      );

  final int id;
  final int orderId;
  final int buyerId;
  final double amount;
  final String currency;
  final String dueDate;
  final double receivedAmount;
  final String status;
}

/// Mirrors backend ReceivableRequest.
class ReceivableDraft {
  const ReceivableDraft({required this.buyerId, required this.amount, required this.currency, required this.dueDate});

  final int buyerId;
  final double amount;
  final String currency;
  final String dueDate;

  Map<String, dynamic> toJson() => {
        'buyerId': buyerId,
        'amount': amount,
        'currency': currency,
        'dueDate': dueDate,
      };
}

/// Mirrors backend PayableResponse — `status` is DERIVED, same as Receivable.
class Payable {
  const Payable({
    required this.id,
    required this.orderId,
    required this.factoryId,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.paidAmount,
    required this.status,
  });

  factory Payable.fromJson(Map<String, dynamic> json) => Payable(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        factoryId: json['factoryId'] as int,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        dueDate: json['dueDate'] as String,
        paidAmount: (json['paidAmount'] as num).toDouble(),
        status: json['status'] as String,
      );

  final int id;
  final int orderId;
  final int factoryId;
  final double amount;
  final String currency;
  final String dueDate;
  final double paidAmount;
  final String status;
}

/// Mirrors backend PayableRequest.
class PayableDraft {
  const PayableDraft({required this.factoryId, required this.amount, required this.currency, required this.dueDate});

  final int factoryId;
  final double amount;
  final String currency;
  final String dueDate;

  Map<String, dynamic> toJson() => {
        'factoryId': factoryId,
        'amount': amount,
        'currency': currency,
        'dueDate': dueDate,
      };
}

/// Mirrors backend PaymentRecordRequest — exactly one of receivableId/payableId
/// is set (the backend atomically updates that record's received/paid total).
class PaymentRecordDraft {
  const PaymentRecordDraft({
    this.receivableId,
    this.payableId,
    required this.amount,
    required this.paidDate,
    this.method,
    this.referenceNo,
  });

  final int? receivableId;
  final int? payableId;
  final double amount;
  final String paidDate;
  final String? method;
  final String? referenceNo;

  Map<String, dynamic> toJson() => {
        'receivableId': receivableId,
        'payableId': payableId,
        'amount': amount,
        'paidDate': paidDate,
        'method': method,
        'referenceNo': referenceNo,
      };
}
