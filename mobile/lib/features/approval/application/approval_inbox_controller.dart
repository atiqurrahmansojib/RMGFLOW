import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/approval_repository_impl.dart';
import '../domain/approval.dart';

sealed class ApprovalInboxState {
  const ApprovalInboxState();
}

class ApprovalInboxLoading extends ApprovalInboxState {
  const ApprovalInboxLoading();
}

class ApprovalInboxLoaded extends ApprovalInboxState {
  const ApprovalInboxLoaded(this.approvals);
  final List<Approval> approvals;
}

class ApprovalInboxError extends ApprovalInboxState {
  const ApprovalInboxError(this.failure);
  final Failure failure;
}

final approvalInboxControllerProvider =
    StateNotifierProvider.autoDispose<ApprovalInboxController, ApprovalInboxState>((ref) {
  return ApprovalInboxController(ref)..load();
});

/// Document 7 (#67): the Pending Approvals Inbox — every target type in one
/// list (ADR-08), each row routes to the right module's detail screen.
class ApprovalInboxController extends StateNotifier<ApprovalInboxState> {
  ApprovalInboxController(this._ref) : super(const ApprovalInboxLoading());

  final Ref _ref;
  ApprovalTargetType? _targetType;

  Future<void> load({ApprovalTargetType? targetType}) async {
    _targetType = targetType;
    state = const ApprovalInboxLoading();
    try {
      final approvals = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(approvalRepositoryProvider).inbox(targetType: _targetType),
          );
      state = ApprovalInboxLoaded(approvals);
    } on DioException catch (e) {
      state = ApprovalInboxError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load(targetType: _targetType);
}
