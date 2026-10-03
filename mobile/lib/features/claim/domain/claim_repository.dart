import 'claim.dart';

/// Document 12.2: domain contract for /api/v1/claims and /orders/{orderId}/claims.
abstract class ClaimRepository {
  Future<List<Claim>> listByOrder(int orderId);
  Future<List<Claim>> listAll();
  Future<Claim> create(int orderId, ClaimDraft draft);
  Future<Claim> resolve(int id, ClaimResolutionDraft draft);
}
