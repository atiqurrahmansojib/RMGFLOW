import 'shipment.dart';

/// Document 12.2: domain contract for /api/v1/orders/{orderId}/shipments (Doc 9.7/9.8/9.11).
abstract class ShipmentRepository {
  Future<List<Shipment>> list(int orderId);
  Future<Shipment> create(int orderId, ShipmentDraft draft);
  Future<Shipment> updateStatus(int orderId, int shipmentId, ShipmentStatus status);
}
