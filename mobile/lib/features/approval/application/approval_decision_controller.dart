import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/approval_repository_impl.dart';
import '../domain/approval.dart';

sealed class ApprovalDecisionState {
  const ApprovalDecisionState();
}

class ApprovalDecisionIdle extends ApprovalDecisionState {
  const ApprovalDecisionIdle();
}

class ApprovalDecisionSubmitting extends ApprovalDecisionState {
  const ApprovalDecisionSubmitting();
}

class ApprovalDecisionSuccess extends ApprovalDecisionState {
  const ApprovalDecisionSuccess(this.approval);
  final Approval approval;
}

class ApprovalDecisionFailed extends ApprovalDecisionState {
  const ApprovalDecisionFailed(this.failure);
  final Failure failure;
}

final approvalDecisionControllerProvider =
    StateNotifierProvider.autoDispose<ApprovalDecisionController, ApprovalDecisionState>((ref) {
  return ApprovalDecisionController(ref);
});

/// Document 7 (#68)/10.2: approve/reject/return a pending round. The backend
/// gates WHO may decide per target type (DECISION_PERMISSION_BY_TARGET_TYPE,
/// fail-closed for any unmapped type) — a 403 here just means this user lacks
/// that specific module's approve permission, surfaced via Failure/SnackBar.
class ApprovalDecisionController extends StateNotifier<ApprovalDecisionState> {
  ApprovalDecisionController(this._ref) : super(const ApprovalDecisionIdle());

  final Ref _ref;

  Future<void> decide(int approvalId, ApprovalDecision decision) async {
    state = const ApprovalDecisionSubmitting();
    try {
      final approval = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(approvalRepositoryProvider).decide(approvalId, decision),
          );
      state = ApprovalDecisionSuccess(approval);
    } on DioException catch (e) {
      state = ApprovalDecisionFailed(mapDioErrorToFailure(e));
    }
  }
}
