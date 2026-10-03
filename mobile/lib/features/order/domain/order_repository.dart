import 'order.dart';

/// Document 12.2: domain contract for /api/v1/orders (+ nested /amendments, Doc 9.4/9.6).
abstract class OrderRepository {
  Future<List<Order>> list({int? buyerId, OrderStatus? status, int page = 0, int size = 25});
  Future<Order> get(int id);
  Future<Order> create(OrderDraft draft);
  Future<void> cancel(int id, String reason);
  Future<List<OrderAmendment>> listAmendments(int orderId);
  Future<OrderAmendment> requestAmendment(int orderId, OrderAmendmentDraft draft);
  Future<OrderAmendment> approveAmendment(int orderId, int amendmentId);
  Future<OrderAmendment> rejectAmendment(int orderId, int amendmentId);
}
