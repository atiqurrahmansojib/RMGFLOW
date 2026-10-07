import 'costing.dart';

/// Document 12.2: domain contract for /api/v1/costings (Doc 11.2/9.1).
abstract class CostingRepository {
  Future<List<Costing>> list({int? styleId, int page = 0, int size = 100});
  Future<Costing> get(int id);
  Future<Costing> create(CostingDraft draft);
  Future<Costing> updateDraft(int id, CostingDraft draft);
  Future<Costing> createRevision(int id, CostingDraft draft);
  Future<Costing> submitForApproval(int id);
}
