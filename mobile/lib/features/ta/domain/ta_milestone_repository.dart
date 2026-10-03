import 'ta_milestone.dart';

/// Document 12.2: domain contract for /api/v1/orders/{orderId}/ta-milestones (Doc 9.5/A15/A16).
abstract class TaMilestoneRepository {
  Future<List<TaMilestone>> list(int orderId);
  Future<List<TaMilestone>> generate(int orderId, int styleId);
  Future<TaMilestone> recordActualDate(int orderId, int milestoneId, RecordActualDateDraft draft);
  Future<TaMilestone> assignResponsibleUser(int orderId, int milestoneId, int userId);
}
