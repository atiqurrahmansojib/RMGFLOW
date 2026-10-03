import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/quotation_repository_impl.dart';
import '../domain/quotation.dart';

sealed class QuotationFormState {
  const QuotationFormState();
}

class QuotationFormIdle extends QuotationFormState {
  const QuotationFormIdle();
}

class QuotationFormSubmitting extends QuotationFormState {
  const QuotationFormSubmitting();
}

class QuotationFormSuccess extends QuotationFormState {
  const QuotationFormSuccess(this.quotation);
  final Quotation quotation;
}

class QuotationFormFailed extends QuotationFormState {
  const QuotationFormFailed(this.failure);
  final Failure failure;
}

final quotationFormControllerProvider =
    StateNotifierProvider.autoDispose<QuotationFormController, QuotationFormState>((ref) {
  return QuotationFormController(ref);
});

/// Document 9.2: create or revise — a quotation requires an APPROVED costing
/// (enforced server-side); revise always produces a new version row.
class QuotationFormController extends StateNotifier<QuotationFormState> {
  QuotationFormController(this._ref) : super(const QuotationFormIdle());

  final Ref _ref;

  Future<void> submit({required QuotationDraft draft, int? reviseId}) async {
    state = const QuotationFormSubmitting();
    try {
      final repo = _ref.read(quotationRepositoryProvider);
      final quotation = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => reviseId == null ? repo.create(draft) : repo.createRevision(reviseId, draft),
          );
      state = QuotationFormSuccess(quotation);
    } on DioException catch (e) {
      state = QuotationFormFailed(mapDioErrorToFailure(e));
    }
  }
}

sealed class QuotationStatusState {
  const QuotationStatusState();
}

class QuotationStatusIdle extends QuotationStatusState {
  const QuotationStatusIdle();
}

class QuotationStatusUpdating extends QuotationStatusState {
  const QuotationStatusUpdating();
}

class QuotationStatusSuccess extends QuotationStatusState {
  const QuotationStatusSuccess(this.quotation);
  final Quotation quotation;
}

class QuotationStatusFailed extends QuotationStatusState {
  const QuotationStatusFailed(this.failure);
  final Failure failure;
}

final quotationStatusControllerProvider =
    StateNotifierProvider.autoDispose<QuotationStatusController, QuotationStatusState>((ref) {
  return QuotationStatusController(ref);
});

/// Document 7 (#42): status-change action (SENT/NEGOTIATING/APPROVED/REJECTED/
/// EXPIRED) — the backend is the real enforcement of legal transitions.
class QuotationStatusController extends StateNotifier<QuotationStatusState> {
  QuotationStatusController(this._ref) : super(const QuotationStatusIdle());

  final Ref _ref;

  Future<void> updateStatus(int id, QuotationStatus status) async {
    state = const QuotationStatusUpdating();
    try {
      final quotation = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(quotationRepositoryProvider).updateStatus(id, status),
          );
      state = QuotationStatusSuccess(quotation);
    } on DioException catch (e) {
      state = QuotationStatusFailed(mapDioErrorToFailure(e));
    }
  }
}
