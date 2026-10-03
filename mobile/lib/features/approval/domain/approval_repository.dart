import 'approval.dart';

/// Document 12.2: domain contract for /api/v1/approvals — the generic engine
/// behind every Costing/Quotation/Sample-Revision/… approval gate (ADR-08).
abstract class ApprovalRepository {
  Future<List<Approval>> inbox({ApprovalTargetType? targetType, int page = 0, int size = 25});
  Future<List<Approval>> history({required ApprovalTargetType targetType, required int targetId});
  Future<Approval> decide(int approvalId, ApprovalDecision decision);
}
