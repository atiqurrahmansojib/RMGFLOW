import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/buyer_repository_impl.dart';
import '../domain/buyer.dart';

sealed class BuyerFormState {
  const BuyerFormState();
}

class BuyerFormIdle extends BuyerFormState {
  const BuyerFormIdle();
}

class BuyerFormSubmitting extends BuyerFormState {
  const BuyerFormSubmitting();
}

class BuyerFormSuccess extends BuyerFormState {
  const BuyerFormSuccess(this.buyer);
  final Buyer buyer;
}

/// Soft-delete finished (Doc 8: master data is deactivated, never hard-deleted).
class BuyerFormDeactivated extends BuyerFormState {
  const BuyerFormDeactivated();
}

class BuyerFormFailed extends BuyerFormState {
  const BuyerFormFailed(this.failure);
  final Failure failure;
}

final buyerFormControllerProvider =
    StateNotifierProvider.autoDispose<BuyerFormController, BuyerFormState>((ref) {
  return BuyerFormController(ref);
});

/// Document 7 (#18): one controller for both create and edit — same form,
/// `existingId == null` means create (Doc 9's immutability rules don't apply
/// to buyer master data the way they do to costing/quotation/order).
class BuyerFormController extends StateNotifier<BuyerFormState> {
  BuyerFormController(this._ref) : super(const BuyerFormIdle());

  final Ref _ref;

  Future<void> submit({required BuyerDraft draft, int? existingId}) async {
    state = const BuyerFormSubmitting();
    try {
      final repo = _ref.read(buyerRepositoryProvider);
      final buyer = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => existingId == null ? repo.create(draft) : repo.update(existingId, draft),
          );
      state = BuyerFormSuccess(buyer);
    } on DioException catch (e) {
      state = BuyerFormFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> deactivate(int id) async {
    state = const BuyerFormSubmitting();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(buyerRepositoryProvider).deactivate(id),
          );
      state = const BuyerFormDeactivated();
    } on DioException catch (e) {
      state = BuyerFormFailed(mapDioErrorToFailure(e));
    }
  }
}
