import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/quality_repository_impl.dart';
import '../domain/quality.dart';

sealed class CapaListState {
  const CapaListState();
}

class CapaListLoading extends CapaListState {
  const CapaListLoading();
}

class CapaListLoaded extends CapaListState {
  const CapaListLoaded(this.records);
  final List<CapaRecord> records;
}

class CapaListError extends CapaListState {
  const CapaListError(this.failure);
  final Failure failure;
}

final capaListByDefectControllerProvider =
    StateNotifierProvider.autoDispose.family<CapaListController, CapaListState, int>((ref, defectId) {
  return CapaListController(ref, byDefectId: defectId)..load();
});

/// Document 7 (#63-64)/9.9: CAPA records — corrective/preventive action
/// tracking, scoped to either a defect or an inspection.
class CapaListController extends StateNotifier<CapaListState> {
  CapaListController(this._ref, {this.byDefectId, this.byInspectionId}) : super(const CapaListLoading());

  final Ref _ref;
  final int? byDefectId;
  final int? byInspectionId;

  Future<void> load() async {
    state = const CapaListLoading();
    try {
      final records = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => byDefectId != null
                ? _ref.read(qualityRepositoryProvider).listCapaByDefect(byDefectId!)
                : _ref.read(qualityRepositoryProvider).listCapaByInspection(byInspectionId!),
          );
      state = CapaListLoaded(records);
    } on DioException catch (e) {
      state = CapaListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class CapaActionState {
  const CapaActionState();
}

class CapaActionIdle extends CapaActionState {
  const CapaActionIdle();
}

class CapaActionInProgress extends CapaActionState {
  const CapaActionInProgress();
}

class CapaActionSuccess extends CapaActionState {
  const CapaActionSuccess(this.record);
  final CapaRecord record;
}

class CapaActionFailed extends CapaActionState {
  const CapaActionFailed(this.failure);
  final Failure failure;
}

final capaActionControllerProvider =
    StateNotifierProvider.autoDispose<CapaActionController, CapaActionState>((ref) {
  return CapaActionController(ref);
});

/// Document 9.9: create -> factory response -> close, the full CAPA lifecycle.
class CapaActionController extends StateNotifier<CapaActionState> {
  CapaActionController(this._ref) : super(const CapaActionIdle());

  final Ref _ref;

  Future<void> create(CapaRecordDraft draft) async {
    state = const CapaActionInProgress();
    try {
      final record = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(qualityRepositoryProvider).createCapa(draft),
          );
      state = CapaActionSuccess(record);
    } on DioException catch (e) {
      state = CapaActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> recordFactoryResponse(int capaId, String response) async {
    state = const CapaActionInProgress();
    try {
      final record = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(qualityRepositoryProvider).recordFactoryResponse(capaId, response),
          );
      state = CapaActionSuccess(record);
    } on DioException catch (e) {
      state = CapaActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> close(int capaId) async {
    state = const CapaActionInProgress();
    try {
      final record = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(qualityRepositoryProvider).closeCapa(capaId),
          );
      state = CapaActionSuccess(record);
    } on DioException catch (e) {
      state = CapaActionFailed(mapDioErrorToFailure(e));
    }
  }
}
