import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/production_repository_impl.dart';
import '../domain/production_update.dart';

sealed class ProductionProgressState {
  const ProductionProgressState();
}

class ProductionProgressLoading extends ProductionProgressState {
  const ProductionProgressLoading();
}

class ProductionProgressLoaded extends ProductionProgressState {
  const ProductionProgressLoaded(this.progress);
  final ProductionProgress progress;
}

class ProductionProgressError extends ProductionProgressState {
  const ProductionProgressError(this.failure);
  final Failure failure;
}

final productionProgressControllerProvider =
    StateNotifierProvider.autoDispose.family<ProductionProgressController, ProductionProgressState, int>(
        (ref, orderId) {
  return ProductionProgressController(ref, orderId)..load();
});

/// Document 7 (#52-53)/9.6: cumulative progress is ALWAYS server-computed
/// from daily updates — this controller only ever displays what comes back.
class ProductionProgressController extends StateNotifier<ProductionProgressState> {
  ProductionProgressController(this._ref, this._orderId) : super(const ProductionProgressLoading());

  final Ref _ref;
  final int _orderId;

  Future<void> load() async {
    state = const ProductionProgressLoading();
    try {
      final progress = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(productionRepositoryProvider).progress(_orderId),
          );
      state = ProductionProgressLoaded(progress);
    } on DioException catch (e) {
      state = ProductionProgressError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class ProductionUpdateFormState {
  const ProductionUpdateFormState();
}

class ProductionUpdateFormIdle extends ProductionUpdateFormState {
  const ProductionUpdateFormIdle();
}

class ProductionUpdateFormSubmitting extends ProductionUpdateFormState {
  const ProductionUpdateFormSubmitting();
}

class ProductionUpdateFormSuccess extends ProductionUpdateFormState {
  const ProductionUpdateFormSuccess(this.update);
  final ProductionUpdate update;
}

class ProductionUpdateFormFailed extends ProductionUpdateFormState {
  const ProductionUpdateFormFailed(this.failure);
  final Failure failure;
}

final productionUpdateFormControllerProvider =
    StateNotifierProvider.autoDispose<ProductionUpdateFormController, ProductionUpdateFormState>((ref) {
  return ProductionUpdateFormController(ref);
});

/// Document 9.6: records one day's line-stage quantities — the packing
/// hard-block (packing can never exceed order quantity) is enforced
/// server-side, surfaced here as a plain 400/ValidationFailure.
class ProductionUpdateFormController extends StateNotifier<ProductionUpdateFormState> {
  ProductionUpdateFormController(this._ref) : super(const ProductionUpdateFormIdle());

  final Ref _ref;

  Future<void> submit(int orderId, ProductionUpdateDraft draft) async {
    state = const ProductionUpdateFormSubmitting();
    try {
      final update = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(productionRepositoryProvider).recordDailyUpdate(orderId, draft),
          );
      state = ProductionUpdateFormSuccess(update);
    } on DioException catch (e) {
      state = ProductionUpdateFormFailed(mapDioErrorToFailure(e));
    }
  }
}
