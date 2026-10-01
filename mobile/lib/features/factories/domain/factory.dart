/// Mirrors backend PartnerType enum (com.rmgflow.factory.entity.PartnerType, Doc 8.2).
enum PartnerType {
  garmentFactory, fabricSupplier, trimSupplier, washing, printing,
  embroidery, testingLab, inspectionAgency, freightForwarder, other;

  String get apiValue => switch (this) {
        PartnerType.garmentFactory => 'GARMENT_FACTORY',
        PartnerType.fabricSupplier => 'FABRIC_SUPPLIER',
        PartnerType.trimSupplier => 'TRIM_SUPPLIER',
        PartnerType.washing => 'WASHING',
        PartnerType.printing => 'PRINTING',
        PartnerType.embroidery => 'EMBROIDERY',
        PartnerType.testingLab => 'TESTING_LAB',
        PartnerType.inspectionAgency => 'INSPECTION_AGENCY',
        PartnerType.freightForwarder => 'FREIGHT_FORWARDER',
        PartnerType.other => 'OTHER',
      };

  String get label => switch (this) {
        PartnerType.garmentFactory => 'Garment Factory',
        PartnerType.fabricSupplier => 'Fabric Supplier',
        PartnerType.trimSupplier => 'Trim Supplier',
        PartnerType.washing => 'Washing',
        PartnerType.printing => 'Printing',
        PartnerType.embroidery => 'Embroidery',
        PartnerType.testingLab => 'Testing Lab',
        PartnerType.inspectionAgency => 'Inspection Agency',
        PartnerType.freightForwarder => 'Freight Forwarder',
        PartnerType.other => 'Other',
      };

  static PartnerType fromApiValue(String value) =>
      PartnerType.values.firstWhere((t) => t.apiValue == value, orElse: () => PartnerType.other);
}

class Factory {
  const Factory({
    required this.id,
    required this.code,
    required this.name,
    required this.partnerType,
    this.legalEntityName,
    this.address,
    this.country,
    this.capacityPerMonth,
    required this.active,
    required this.version,
  });

  factory Factory.fromJson(Map<String, dynamic> json) => Factory(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        partnerType: PartnerType.fromApiValue(json['partnerType'] as String),
        legalEntityName: json['legalEntityName'] as String?,
        address: json['address'] as String?,
        country: json['country'] as String?,
        capacityPerMonth: json['capacityPerMonth'] as int?,
        active: json['active'] as bool,
        version: json['version'] as int,
      );

  final int id;
  final String code;
  final String name;
  final PartnerType partnerType;
  final String? legalEntityName;
  final String? address;
  final String? country;
  final int? capacityPerMonth;
  final bool active;
  final int version;
}

class FactoryDraft {
  const FactoryDraft({
    required this.code,
    required this.name,
    required this.partnerType,
    this.legalEntityName,
    this.address,
    this.country,
    this.capacityPerMonth,
    this.version,
  });

  final String code;
  final String name;
  final PartnerType partnerType;
  final String? legalEntityName;
  final String? address;
  final String? country;
  final int? capacityPerMonth;
  final int? version;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'partnerType': partnerType.apiValue,
        'legalEntityName': legalEntityName,
        'address': address,
        'country': country,
        'capacityPerMonth': capacityPerMonth,
        'version': version,
      };
}
