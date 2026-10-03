/// Mirrors backend ProductionUpdateResponse — one daily entry.
class ProductionUpdate {
  const ProductionUpdate({
    required this.id,
    required this.orderId,
    required this.updateDate,
    required this.cuttingQty,
    required this.sewingQty,
    required this.finishingQty,
    required this.packingQty,
    required this.rejectionQty,
    required this.alterationQty,
  });

  factory ProductionUpdate.fromJson(Map<String, dynamic> json) => ProductionUpdate(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        updateDate: json['updateDate'] as String,
        cuttingQty: json['cuttingQty'] as int,
        sewingQty: json['sewingQty'] as int,
        finishingQty: json['finishingQty'] as int,
        packingQty: json['packingQty'] as int,
        rejectionQty: json['rejectionQty'] as int,
        alterationQty: json['alterationQty'] as int,
      );

  final int id;
  final int orderId;
  final String updateDate;
  final int cuttingQty;
  final int sewingQty;
  final int finishingQty;
  final int packingQty;
  final int rejectionQty;
  final int alterationQty;
}

/// Mirrors backend ProductionUpdateRequest.
class ProductionUpdateDraft {
  const ProductionUpdateDraft({
    required this.updateDate,
    required this.cuttingQty,
    required this.sewingQty,
    required this.finishingQty,
    required this.packingQty,
    required this.rejectionQty,
    required this.alterationQty,
  });

  final String updateDate;
  final int cuttingQty;
  final int sewingQty;
  final int finishingQty;
  final int packingQty;
  final int rejectionQty;
  final int alterationQty;

  Map<String, dynamic> toJson() => {
        'updateDate': updateDate,
        'cuttingQty': cuttingQty,
        'sewingQty': sewingQty,
        'finishingQty': finishingQty,
        'packingQty': packingQty,
        'rejectionQty': rejectionQty,
        'alterationQty': alterationQty,
      };
}

/// Mirrors backend ProductionProgressResponse — Doc 9.6/14.4: the cumulative
/// rollup is ALWAYS server-computed from daily updates, never a client running
/// total; `packingProgressPercent` is similarly derived, never recalculated here.
class ProductionProgress {
  const ProductionProgress({
    required this.orderId,
    required this.orderQuantity,
    required this.cumulativeCutting,
    required this.cumulativeSewing,
    required this.cumulativeFinishing,
    required this.cumulativePacking,
    required this.cumulativeRejection,
    required this.cumulativeAlteration,
    required this.packingProgressPercent,
    required this.dailyUpdates,
  });

  factory ProductionProgress.fromJson(Map<String, dynamic> json) => ProductionProgress(
        orderId: json['orderId'] as int,
        orderQuantity: json['orderQuantity'] as int,
        cumulativeCutting: json['cumulativeCutting'] as int,
        cumulativeSewing: json['cumulativeSewing'] as int,
        cumulativeFinishing: json['cumulativeFinishing'] as int,
        cumulativePacking: json['cumulativePacking'] as int,
        cumulativeRejection: json['cumulativeRejection'] as int,
        cumulativeAlteration: json['cumulativeAlteration'] as int,
        packingProgressPercent: (json['packingProgressPercent'] as num).toDouble(),
        dailyUpdates: (json['dailyUpdates'] as List? ?? [])
            .map((e) => ProductionUpdate.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int orderId;
  final int orderQuantity;
  final int cumulativeCutting;
  final int cumulativeSewing;
  final int cumulativeFinishing;
  final int cumulativePacking;
  final int cumulativeRejection;
  final int cumulativeAlteration;
  final double packingProgressPercent;
  final List<ProductionUpdate> dailyUpdates;
}
