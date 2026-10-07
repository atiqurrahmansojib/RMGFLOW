import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/costing_repository_impl.dart';
import '../domain/costing.dart';

sealed class CostingFormState {
  const CostingFormState();
}

class CostingFormIdle extends CostingFormState {
  const CostingFormIdle();
}

class CostingFormSubmitting extends CostingFormState {
  const CostingFormSubmitting();
}

class CostingFormSuccess extends CostingFormState {
  const CostingFormSuccess(this.costing);
  final Costing costing;
}

class CostingFormFailed extends CostingFormState {
  const CostingFormFailed(this.failure);
  final Failure failure;
}

enum CostingFormMode { create, editDraft, revise }

final costingFormControllerProvider = StateNotifierProvider.autoDispose<CostingFormController, CostingFormState>((ref) {
  return CostingFormController(ref);
});

/// Document 9.1: one controller for create / edit-draft / revise — the backend
/// enforces which is legal for a given status (DRAFT-only edit; revise always
/// allowed, producing a new version row rather than mutating an APPROVED one).
class CostingFormController extends StateNotifier<CostingFormState> {
  CostingFormController(this._ref) : super(const CostingFormIdle());

  final Ref _ref;

  Future<void> submit({
    required CostingDraft draft,
    required CostingFormMode mode,
    int? existingId,
  }) async {
    state = const CostingFormSubmitting();
    try {
      final repo = _ref.read(costingRepositoryProvider);
      final costing = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => switch (mode) {
              CostingFormMode.create => repo.create(draft),
              CostingFormMode.editDraft => repo.updateDraft(existingId!, draft),
              CostingFormMode.revise => repo.createRevision(existingId!, draft),
            },
          );
      state = CostingFormSuccess(costing);
    } on DioException catch (e) {
      state = CostingFormFailed(mapDioErrorToFailure(e));
    }
  }
}

sealed class CostingSubmitState {
  const CostingSubmitState();
}

class CostingSubmitIdle extends CostingSubmitState {
  const CostingSubmitIdle();
}

class CostingSubmitting extends CostingSubmitState {
  const CostingSubmitting();
}

class CostingSubmitSuccess extends CostingSubmitState {
  const CostingSubmitSuccess(this.costing);
  final Costing costing;
}

class CostingSubmitFailed extends CostingSubmitState {
  const CostingSubmitFailed(this.failure);
  final Failure failure;
}

final costingSubmitControllerProvider =
    StateNotifierProvider.autoDispose<CostingSubmitController, CostingSubmitState>((ref) {
  return CostingSubmitController(ref);
});

/// Document 10.2: "Submit for Approval" — hands the costing to the shared
/// Approval Engine (Doc ADR-08); the costing itself stays DRAFT until a
/// COSTING_APPROVE-permitted user decides the resulting round.
class CostingSubmitController extends StateNotifier<CostingSubmitState> {
  CostingSubmitController(this._ref) : super(const CostingSubmitIdle());

  final Ref _ref;

  Future<void> submitForApproval(int costingId) async {
    state = const CostingSubmitting();
    try {
      final costing = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(costingRepositoryProvider).submitForApproval(costingId),
          );
      state = CostingSubmitSuccess(costing);
    } on DioException catch (e) {
      state = CostingSubmitFailed(mapDioErrorToFailure(e));
    }
  }
}
