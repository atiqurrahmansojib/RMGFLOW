/// Mirrors backend StyleResponse (com.rmgflow.style.dto.StyleResponse, Doc 8.3).
class Style {
  const Style({
    required this.id,
    required this.styleNo,
    required this.buyerId,
    this.buyerStyleNo,
    this.productCategory,
    this.seasonId,
    this.gender,
    this.description,
    this.currentRevisionId,
    required this.active,
  });

  factory Style.fromJson(Map<String, dynamic> json) => Style(
        id: json['id'] as int,
        styleNo: json['styleNo'] as String,
        buyerId: json['buyerId'] as int,
        buyerStyleNo: json['buyerStyleNo'] as String?,
        productCategory: json['productCategory'] as String?,
        seasonId: json['seasonId'] as int?,
        gender: json['gender'] as String?,
        description: json['description'] as String?,
        currentRevisionId: json['currentRevisionId'] as int?,
        active: json['active'] as bool,
      );

  final int id;
  final String styleNo;
  final int buyerId;
  final String? buyerStyleNo;
  final String? productCategory;
  final int? seasonId;
  final String? gender;
  final String? description;
  final int? currentRevisionId;
  final bool active;
}

class StyleDraft {
  const StyleDraft({
    required this.styleNo,
    required this.buyerId,
    this.buyerStyleNo,
    this.productCategory,
    this.seasonId,
    this.gender,
    this.description,
  });

  final String styleNo;
  final int buyerId;
  final String? buyerStyleNo;
  final String? productCategory;
  final int? seasonId;
  final String? gender;
  final String? description;

  Map<String, dynamic> toJson() => {
        'styleNo': styleNo,
        'buyerId': buyerId,
        'buyerStyleNo': buyerStyleNo,
        'productCategory': productCategory,
        'seasonId': seasonId,
        'gender': gender,
        'description': description,
      };
}
