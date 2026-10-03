import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/quality_repository_impl.dart';
import '../domain/quality.dart';

sealed class InspectionListState {
  const InspectionListState();
}

class InspectionListLoading extends InspectionListState {
  const InspectionListLoading();
}

class InspectionListLoaded extends InspectionListState {
  const InspectionListLoaded(this.inspections);
  final List<Inspection> inspections;
}

class InspectionListError extends InspectionListState {
  const InspectionListError(this.failure);
  final Failure failure;
}

final inspectionListControllerProvider =
    StateNotifierProvider.autoDispose.family<InspectionListController, InspectionListState, int>((ref, orderId) {
  return InspectionListController(ref, orderId)..load();
});

/// Document 7 (#59-62): one order's inspection history (inline/midline/final).
class InspectionListController extends StateNotifier<InspectionListState> {
  InspectionListController(this._ref, this._orderId) : super(const InspectionListLoading());

  final Ref _ref;
  final int _orderId;

  Future<void> load() async {
    state = const InspectionListLoading();
    try {
      final inspections = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(qualityRepositoryProvider).listInspections(_orderId),
          );
      state = InspectionListLoaded(inspections);
    } on DioException catch (e) {
      state = InspectionListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class InspectionFormState {
  const InspectionFormState();
}

class InspectionFormIdle extends InspectionFormState {
  const InspectionFormIdle();
}

class InspectionFormSubmitting extends InspectionFormState {
  const InspectionFormSubmitting();
}

class InspectionFormSuccess extends InspectionFormState {
  const InspectionFormSuccess(this.inspection);
  final Inspection inspection;
}

class InspectionFormFailed extends InspectionFormState {
  const InspectionFormFailed(this.failure);
  final Failure failure;
}

final inspectionFormControllerProvider =
    StateNotifierProvider.autoDispose<InspectionFormController, InspectionFormState>((ref) {
  return InspectionFormController(ref);
});

/// Document 9.7/9.8: a FAIL/REINSPECT result is what the shipment quality
/// gate checks server-side (`InspectionService.hasPassingFinalInspection()`)
/// — this form just records the result, the gate enforcement lives entirely
/// in the shipment module.
class InspectionFormController extends StateNotifier<InspectionFormState> {
  InspectionFormController(this._ref) : super(const InspectionFormIdle());

  final Ref _ref;

  Future<void> submit(int orderId, InspectionDraft draft) async {
    state = const InspectionFormSubmitting();
    try {
      final inspection = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(qualityRepositoryProvider).createInspection(orderId, draft),
          );
      state = InspectionFormSuccess(inspection);
    } on DioException catch (e) {
      state = InspectionFormFailed(mapDioErrorToFailure(e));
    }
  }
}
