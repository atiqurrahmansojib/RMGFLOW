/// Mirrors backend OrderStatus (com.rmgflow.order.entity.OrderStatus).
enum OrderStatus {
  confirmed, inProgress, partiallyShipped, shipped, closed, cancelled;

  String get apiValue => switch (this) {
        OrderStatus.inProgress => 'IN_PROGRESS',
        OrderStatus.partiallyShipped => 'PARTIALLY_SHIPPED',
        _ => name.toUpperCase(),
      };

  String get label => switch (this) {
        OrderStatus.inProgress => 'In Progress',
        OrderStatus.partiallyShipped => 'Partially Shipped',
        _ => name[0].toUpperCase() + name.substring(1),
      };

  static OrderStatus fromApiValue(String value) =>
      OrderStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend OrderItemResponse.
class OrderItem {
  const OrderItem({
    required this.id,
    required this.styleId,
    required this.factoryId,
    this.color,
    this.size,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as int,
        styleId: json['styleId'] as int,
        factoryId: json['factoryId'] as int,
        color: json['color'] as String?,
        size: json['size'] as String?,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
      );

  final int id;
  final int styleId;
  final int factoryId;
  final String? color;
  final String? size;
  final int quantity;
  final double unitPrice;
}

/// Mirrors backend OrderItemRequest.
class OrderItemDraft {
  const OrderItemDraft({
    required this.styleId,
    required this.factoryId,
    this.color,
    this.size,
    required this.quantity,
    required this.unitPrice,
  });

  final int styleId;
  final int factoryId;
  final String? color;
  final String? size;
  final int quantity;
  final double unitPrice;

  Map<String, dynamic> toJson() => {
        'styleId': styleId,
        'factoryId': factoryId,
        'color': color,
        'size': size,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}

/// Mirrors backend OrderResponse — totalValue is server-computed from items.
class Order {
  const Order({
    required this.id,
    required this.orderNo,
    required this.buyerPoNo,
    required this.buyerId,
    this.quotationId,
    required this.status,
    required this.orderDate,
    this.exFactoryDate,
    this.deliveryDate,
    this.incoterm,
    this.paymentTermsId,
    this.destinationCountry,
    required this.totalValue,
    required this.currency,
    required this.version,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        orderNo: json['orderNo'] as String,
        buyerPoNo: json['buyerPoNo'] as String,
        buyerId: json['buyerId'] as int,
        quotationId: json['quotationId'] as int?,
        status: OrderStatus.fromApiValue(json['status'] as String),
        orderDate: json['orderDate'] as String,
        exFactoryDate: json['exFactoryDate'] as String?,
        deliveryDate: json['deliveryDate'] as String?,
        incoterm: json['incoterm'] as String?,
        paymentTermsId: json['paymentTermsId'] as int?,
        destinationCountry: json['destinationCountry'] as String?,
        totalValue: (json['totalValue'] as num).toDouble(),
        currency: json['currency'] as String,
        version: json['version'] as int,
        items: (json['items'] as List? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String orderNo;
  final String buyerPoNo;
  final int buyerId;
  final int? quotationId;
  final OrderStatus status;
  final String orderDate;
  final String? exFactoryDate;
  final String? deliveryDate;
  final String? incoterm;
  final int? paymentTermsId;
  final String? destinationCountry;
  final double totalValue;
  final String currency;
  final int version;
  final List<OrderItem> items;
}

/// Mirrors backend OrderRequest. `overrideFactoryApproval`/`overrideReason`
/// exist because Doc 9.4's factory-buyer-approval gate is permission-gated,
/// not absolute — a user with ORDER_OVERRIDE_FACTORY_APPROVAL may bypass it
/// with a recorded reason (audited).
class OrderDraft {
  const OrderDraft({
    required this.buyerPoNo,
    required this.buyerId,
    this.quotationId,
    required this.orderDate,
    this.exFactoryDate,
    this.deliveryDate,
    this.incoterm,
    this.paymentTermsId,
    this.destinationCountry,
    required this.currency,
    this.overrideFactoryApproval = false,
    this.overrideReason,
    required this.items,
  });

  final String buyerPoNo;
  final int buyerId;
  final int? quotationId;
  final String orderDate;
  final String? exFactoryDate;
  final String? deliveryDate;
  final String? incoterm;
  final int? paymentTermsId;
  final String? destinationCountry;
  final String currency;
  final bool overrideFactoryApproval;
  final String? overrideReason;
  final List<OrderItemDraft> items;

  Map<String, dynamic> toJson() => {
        'buyerPoNo': buyerPoNo,
        'buyerId': buyerId,
        'quotationId': quotationId,
        'orderDate': orderDate,
        'exFactoryDate': exFactoryDate,
        'deliveryDate': deliveryDate,
        'incoterm': incoterm,
        'paymentTermsId': paymentTermsId,
        'destinationCountry': destinationCountry,
        'currency': currency,
        'overrideFactoryApproval': overrideFactoryApproval,
        'overrideReason': overrideReason,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// Mirrors backend OrderAmendmentStatus.
enum OrderAmendmentStatus {
  requested, approved, rejected;

  String get apiValue => name.toUpperCase();

  String get label => name[0].toUpperCase() + name.substring(1);

  static OrderAmendmentStatus fromApiValue(String value) =>
      OrderAmendmentStatus.values.firstWhere((s) => s.apiValue == value);
}

/// Mirrors backend OrderAmendmentResponse.
class OrderAmendment {
  const OrderAmendment({
    required this.id,
    required this.orderId,
    required this.amendmentNo,
    required this.fieldChanged,
    this.oldValue,
    this.newValue,
    required this.reason,
    this.requestedById,
    this.approvedById,
    required this.status,
    required this.createdAt,
  });

  factory OrderAmendment.fromJson(Map<String, dynamic> json) => OrderAmendment(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        amendmentNo: json['amendmentNo'] as int,
        fieldChanged: json['fieldChanged'] as String,
        oldValue: json['oldValue'] as String?,
        newValue: json['newValue'] as String?,
        reason: json['reason'] as String,
        requestedById: json['requestedById'] as int?,
        approvedById: json['approvedById'] as int?,
        status: OrderAmendmentStatus.fromApiValue(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final int id;
  final int orderId;
  final int amendmentNo;
  final String fieldChanged;
  final String? oldValue;
  final String? newValue;
  final String reason;
  final int? requestedById;
  final int? approvedById;
  final OrderAmendmentStatus status;
  final DateTime createdAt;
}

/// Mirrors backend OrderAmendmentRequest.
class OrderAmendmentDraft {
  const OrderAmendmentDraft({required this.fieldChanged, this.newValue, required this.reason});

  final String fieldChanged;
  final String? newValue;
  final String reason;

  Map<String, dynamic> toJson() => {
        'fieldChanged': fieldChanged,
        'newValue': newValue,
        'reason': reason,
      };
}
