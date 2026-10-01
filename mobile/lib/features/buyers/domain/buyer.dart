/// Mirrors backend BuyerResponse (com.rmgflow.buyer.dto.BuyerResponse, Doc 11.2).
class Buyer {
  const Buyer({
    required this.id,
    required this.code,
    required this.name,
    this.groupName,
    this.country,
    this.defaultCurrency,
    this.defaultPaymentTermsId,
    this.defaultIncoterm,
    required this.active,
    required this.version,
  });

  factory Buyer.fromJson(Map<String, dynamic> json) => Buyer(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        groupName: json['groupName'] as String?,
        country: json['country'] as String?,
        defaultCurrency: json['defaultCurrency'] as String?,
        defaultPaymentTermsId: json['defaultPaymentTermsId'] as int?,
        defaultIncoterm: json['defaultIncoterm'] as String?,
        active: json['active'] as bool,
        version: json['version'] as int,
      );

  final int id;
  final String code;
  final String name;
  final String? groupName;
  final String? country;
  final String? defaultCurrency;
  final int? defaultPaymentTermsId;
  final String? defaultIncoterm;
  final bool active;
  final int version;
}

/// Mirrors backend BuyerRequest — null `version` means "create", non-null means "update".
class BuyerDraft {
  const BuyerDraft({
    required this.code,
    required this.name,
    this.groupName,
    this.country,
    this.defaultCurrency,
    this.defaultPaymentTermsId,
    this.defaultIncoterm,
    this.version,
  });

  final String code;
  final String name;
  final String? groupName;
  final String? country;
  final String? defaultCurrency;
  final int? defaultPaymentTermsId;
  final String? defaultIncoterm;
  final int? version;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'groupName': groupName,
        'country': country,
        'defaultCurrency': defaultCurrency,
        'defaultPaymentTermsId': defaultPaymentTermsId,
        'defaultIncoterm': defaultIncoterm,
        'version': version,
      };
}
