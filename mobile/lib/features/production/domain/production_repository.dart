import 'production_update.dart';

/// Document 12.2: domain contract for /api/v1/orders/{orderId}/production-updates (Doc 9.6/14.4).
abstract class ProductionRepository {
  Future<ProductionProgress> progress(int orderId);
  Future<ProductionUpdate> recordDailyUpdate(int orderId, ProductionUpdateDraft draft);
}
