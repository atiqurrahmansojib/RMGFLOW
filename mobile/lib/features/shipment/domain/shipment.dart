/// Mirrors backend ShipmentStatus.
enum ShipmentStatus {
  booked, inTransit, delivered, delayed;

  String get apiValue => this == ShipmentStatus.inTransit ? 'IN_TRANSIT' : name.toUpperCase();

  String get label => this == ShipmentStatus.inTransit ? 'In Transit' : name[0].toUpperCase() + name.substring(1);

  static ShipmentStatus fromApiValue(String value) =>
      ShipmentStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend ShipmentResponse.
class Shipment {
  const Shipment({
    required this.id,
    required this.shipmentNo,
    required this.orderId,
    this.shipmentDate,
    this.etd,
    this.eta,
    required this.quantityShipped,
    this.cartons,
    this.grossWeight,
    this.netWeight,
    this.volumeCbm,
    this.portOfLoading,
    this.portOfDischarge,
    this.forwarderId,
    this.shippingLine,
    this.containerNo,
    this.blAwbNo,
    required this.status,
    required this.partial,
    this.authorizedById,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
        id: json['id'] as int,
        shipmentNo: json['shipmentNo'] as String,
        orderId: json['orderId'] as int,
        shipmentDate: json['shipmentDate'] as String?,
        etd: json['etd'] as String?,
        eta: json['eta'] as String?,
        quantityShipped: json['quantityShipped'] as int,
        cartons: json['cartons'] as int?,
        grossWeight: (json['grossWeight'] as num?)?.toDouble(),
        netWeight: (json['netWeight'] as num?)?.toDouble(),
        volumeCbm: (json['volumeCbm'] as num?)?.toDouble(),
        portOfLoading: json['portOfLoading'] as String?,
        portOfDischarge: json['portOfDischarge'] as String?,
        forwarderId: json['forwarderId'] as int?,
        shippingLine: json['shippingLine'] as String?,
        containerNo: json['containerNo'] as String?,
        blAwbNo: json['blAwbNo'] as String?,
        status: ShipmentStatus.fromApiValue(json['status'] as String),
        partial: json['partial'] as bool,
        authorizedById: json['authorizedById'] as int?,
      );

  final int id;
  final String shipmentNo;
  final int orderId;
  final String? shipmentDate;
  final String? etd;
  final String? eta;
  final int quantityShipped;
  final int? cartons;
  final double? grossWeight;
  final double? netWeight;
  final double? volumeCbm;
  final String? portOfLoading;
  final String? portOfDischarge;
  final int? forwarderId;
  final String? shippingLine;
  final String? containerNo;
  final String? blAwbNo;
  final ShipmentStatus status;
  final bool partial;
  final int? authorizedById;
}

/// Mirrors backend ShipmentRequest. Doc 9.7/9.8/9.11 #5: three server-side
/// gates guard creation — quality (overridable via `overrideQualityGate`),
/// quantity (shipment never exceeds order quantity, NO override exists), and
/// partial-shipment authorization. This layer never evaluates any of them.
class ShipmentDraft {
  const ShipmentDraft({
    this.shipmentDate,
    this.etd,
    this.eta,
    required this.quantityShipped,
    this.cartons,
    this.grossWeight,
    this.netWeight,
    this.volumeCbm,
    this.portOfLoading,
    this.portOfDischarge,
    this.forwarderId,
    this.shippingLine,
    this.containerNo,
    this.blAwbNo,
    this.overrideQualityGate = false,
    this.overrideReason,
  });

  final String? shipmentDate;
  final String? etd;
  final String? eta;
  final int quantityShipped;
  final int? cartons;
  final double? grossWeight;
  final double? netWeight;
  final double? volumeCbm;
  final String? portOfLoading;
  final String? portOfDischarge;
  final int? forwarderId;
  final String? shippingLine;
  final String? containerNo;
  final String? blAwbNo;
  final bool overrideQualityGate;
  final String? overrideReason;

  Map<String, dynamic> toJson() => {
        'shipmentDate': shipmentDate,
        'etd': etd,
        'eta': eta,
        'quantityShipped': quantityShipped,
        'cartons': cartons,
        'grossWeight': grossWeight,
        'netWeight': netWeight,
        'volumeCbm': volumeCbm,
        'portOfLoading': portOfLoading,
        'portOfDischarge': portOfDischarge,
        'forwarderId': forwarderId,
        'shippingLine': shippingLine,
        'containerNo': containerNo,
        'blAwbNo': blAwbNo,
        'overrideQualityGate': overrideQualityGate,
        'overrideReason': overrideReason,
      };
}
