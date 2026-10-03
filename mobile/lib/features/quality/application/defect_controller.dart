import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/quality_repository_impl.dart';
import '../domain/quality.dart';

sealed class DefectListState {
  const DefectListState();
}

class DefectListLoading extends DefectListState {
  const DefectListLoading();
}

class DefectListLoaded extends DefectListState {
  const DefectListLoaded(this.defects);
  final List<Defect> defects;
}

class DefectListError extends DefectListState {
  const DefectListError(this.failure);
  final Failure failure;
}

final defectListControllerProvider =
    StateNotifierProvider.autoDispose.family<DefectListController, DefectListState, int>((ref, inspectionId) {
  return DefectListController(ref, inspectionId)..load();
});

/// Document 7 (#60-61): defects logged against one inspection.
class DefectListController extends StateNotifier<DefectListState> {
  DefectListController(this._ref, this._inspectionId) : super(const DefectListLoading());

  final Ref _ref;
  final int _inspectionId;

  Future<void> load() async {
    state = const DefectListLoading();
    try {
      final defects = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(qualityRepositoryProvider).listDefects(_inspectionId),
          );
      state = DefectListLoaded(defects);
    } on DioException catch (e) {
      state = DefectListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class DefectFormState {
  const DefectFormState();
}

class DefectFormIdle extends DefectFormState {
  const DefectFormIdle();
}

class DefectFormSubmitting extends DefectFormState {
  const DefectFormSubmitting();
}

class DefectFormSuccess extends DefectFormState {
  const DefectFormSuccess(this.defect);
  final Defect defect;
}

class DefectFormFailed extends DefectFormState {
  const DefectFormFailed(this.failure);
  final Failure failure;
}

final defectFormControllerProvider =
    StateNotifierProvider.autoDispose<DefectFormController, DefectFormState>((ref) {
  return DefectFormController(ref);
});

/// Document 7 (#61): logging a defect against an inspection.
class DefectFormController extends StateNotifier<DefectFormState> {
  DefectFormController(this._ref) : super(const DefectFormIdle());

  final Ref _ref;

  Future<void> submit(int inspectionId, DefectDraft draft) async {
    state = const DefectFormSubmitting();
    try {
      final defect = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(qualityRepositoryProvider).createDefect(inspectionId, draft),
          );
      state = DefectFormSuccess(defect);
    } on DioException catch (e) {
      state = DefectFormFailed(mapDioErrorToFailure(e));
    }
  }
}
