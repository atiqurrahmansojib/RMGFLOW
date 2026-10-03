/// Mirrors backend CostingComponentType (com.rmgflow.costing.entity.CostingComponentType, Doc 8.5/10).
enum CostingComponentType {
  fabric, knitting, dyeing, finishing, trims, cm, washing, printing, embroidery,
  testing, inspection, packaging, freight, commission, bankCharge, wastage, overhead, other;

  String get apiValue => switch (this) {
        CostingComponentType.bankCharge => 'BANK_CHARGE',
        _ => name.toUpperCase(),
      };

  String get label => switch (this) {
        CostingComponentType.cm => 'CM',
        CostingComponentType.bankCharge => 'Bank Charge',
        _ => name[0].toUpperCase() + name.substring(1),
      };

  static CostingComponentType fromApiValue(String value) =>
      CostingComponentType.values.firstWhere((t) => t.apiValue == value);
}

/// Mirrors backend CostingStatus (com.rmgflow.costing.entity.CostingStatus, Doc 8.5).
enum CostingStatus {
  draft, approved, superseded;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static CostingStatus fromApiValue(String value) =>
      CostingStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend CostingItemResponse.
class CostingItem {
  const CostingItem({
    required this.id,
    required this.componentType,
    this.description,
    required this.unitCost,
    required this.consumption,
    required this.wastagePercent,
    required this.totalCost,
  });

  factory CostingItem.fromJson(Map<String, dynamic> json) => CostingItem(
        id: json['id'] as int,
        componentType: CostingComponentType.fromApiValue(json['componentType'] as String),
        description: json['description'] as String?,
        unitCost: (json['unitCost'] as num).toDouble(),
        consumption: (json['consumption'] as num).toDouble(),
        wastagePercent: (json['wastagePercent'] as num).toDouble(),
        totalCost: (json['totalCost'] as num).toDouble(),
      );

  final int id;
  final CostingComponentType componentType;
  final String? description;
  final double unitCost;
  final double consumption;
  final double wastagePercent;
  final double totalCost;
}

/// Mirrors backend CostingItemRequest — the id is client-local only (never sent).
class CostingItemDraft {
  const CostingItemDraft({
    required this.componentType,
    this.description,
    required this.unitCost,
    required this.consumption,
    required this.wastagePercent,
  });

  final CostingComponentType componentType;
  final String? description;
  final double unitCost;
  final double consumption;
  final double wastagePercent;

  Map<String, dynamic> toJson() => {
        'componentType': componentType.apiValue,
        'description': description,
        'unitCost': unitCost,
        'consumption': consumption,
        'wastagePercent': wastagePercent,
      };
}

/// Mirrors backend CostingResponse (Doc 9.1/ADR-14): server-computed totalCost/
/// marginPercent — never recomputed client-side (NFR-01).
class Costing {
  const Costing({
    required this.id,
    required this.styleId,
    this.inquiryId,
    required this.versionNo,
    required this.currency,
    required this.exchangeRate,
    required this.quantity,
    required this.status,
    this.targetPrice,
    required this.totalCost,
    this.marginPercent,
    this.supersededFromId,
    required this.version,
    required this.items,
  });

  factory Costing.fromJson(Map<String, dynamic> json) => Costing(
        id: json['id'] as int,
        styleId: json['styleId'] as int,
        inquiryId: json['inquiryId'] as int?,
        versionNo: json['versionNo'] as int,
        currency: json['currency'] as String,
        exchangeRate: (json['exchangeRate'] as num).toDouble(),
        quantity: json['quantity'] as int,
        status: CostingStatus.fromApiValue(json['status'] as String),
        targetPrice: (json['targetPrice'] as num?)?.toDouble(),
        totalCost: (json['totalCost'] as num).toDouble(),
        marginPercent: (json['marginPercent'] as num?)?.toDouble(),
        supersededFromId: json['supersededFromId'] as int?,
        version: json['version'] as int,
        items: (json['items'] as List? ?? [])
            .map((e) => CostingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final int styleId;
  final int? inquiryId;
  final int versionNo;
  final String currency;
  final double exchangeRate;
  final int quantity;
  final CostingStatus status;
  final double? targetPrice;
  final double totalCost;
  final double? marginPercent;
  final int? supersededFromId;
  final int version;
  final List<CostingItem> items;
}

/// Mirrors backend CostingRequest.
class CostingDraft {
  const CostingDraft({
    required this.styleId,
    this.inquiryId,
    required this.currency,
    required this.exchangeRate,
    required this.quantity,
    this.targetPrice,
    required this.items,
  });

  final int styleId;
  final int? inquiryId;
  final String currency;
  final double exchangeRate;
  final int quantity;
  final double? targetPrice;
  final List<CostingItemDraft> items;

  Map<String, dynamic> toJson() => {
        'styleId': styleId,
        'inquiryId': inquiryId,
        'currency': currency,
        'exchangeRate': exchangeRate,
        'quantity': quantity,
        'targetPrice': targetPrice,
        'items': items.map((i) => i.toJson()).toList(),
      };
}
