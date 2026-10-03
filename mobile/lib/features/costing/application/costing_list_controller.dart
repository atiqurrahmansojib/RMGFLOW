import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/costing_repository_impl.dart';
import '../domain/costing.dart';

sealed class CostingListState {
  const CostingListState();
}

class CostingListLoading extends CostingListState {
  const CostingListLoading();
}

class CostingListLoaded extends CostingListState {
  const CostingListLoaded(this.costings);
  final List<Costing> costings;
}

class CostingListError extends CostingListState {
  const CostingListError(this.failure);
  final Failure failure;
}

final costingListControllerProvider =
    StateNotifierProvider.autoDispose<CostingListController, CostingListState>((ref) {
  return CostingListController(ref)..load();
});

/// Document 7 (#37-39): costing list, optionally filtered by style.
class CostingListController extends StateNotifier<CostingListState> {
  CostingListController(this._ref, {int? styleId})
      : _styleId = styleId,
        super(const CostingListLoading());

  final Ref _ref;
  int? _styleId;

  Future<void> load({int? styleId}) async {
    if (styleId != null) _styleId = styleId;
    state = const CostingListLoading();
    try {
      final costings = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(costingRepositoryProvider).list(styleId: _styleId),
          );
      state = CostingListLoaded(costings);
    } on DioException catch (e) {
      state = CostingListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}
