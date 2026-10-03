import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/order_repository_impl.dart';
import '../domain/order.dart';

sealed class OrderActionState {
  const OrderActionState();
}

class OrderActionIdle extends OrderActionState {
  const OrderActionIdle();
}

class OrderActionInProgress extends OrderActionState {
  const OrderActionInProgress();
}

class OrderActionSuccess extends OrderActionState {
  const OrderActionSuccess();
}

class OrderActionFailed extends OrderActionState {
  const OrderActionFailed(this.failure);
  final Failure failure;
}

final orderActionControllerProvider =
    StateNotifierProvider.autoDispose<OrderActionController, OrderActionState>((ref) {
  return OrderActionController(ref);
});

/// Document 9.6: order cancellation and the amendment request/approve/reject
/// flow — every historical order field change is a recorded amendment, never
/// a silent edit (Doc 8.5's immutability rule for confirmed orders).
class OrderActionController extends StateNotifier<OrderActionState> {
  OrderActionController(this._ref) : super(const OrderActionIdle());

  final Ref _ref;

  Future<void> cancel(int orderId, String reason) async {
    state = const OrderActionInProgress();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(orderRepositoryProvider).cancel(orderId, reason),
          );
      state = const OrderActionSuccess();
    } on DioException catch (e) {
      state = OrderActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> requestAmendment(int orderId, OrderAmendmentDraft draft) async {
    state = const OrderActionInProgress();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(orderRepositoryProvider).requestAmendment(orderId, draft),
          );
      state = const OrderActionSuccess();
    } on DioException catch (e) {
      state = OrderActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> approveAmendment(int orderId, int amendmentId) async {
    state = const OrderActionInProgress();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(orderRepositoryProvider).approveAmendment(orderId, amendmentId),
          );
      state = const OrderActionSuccess();
    } on DioException catch (e) {
      state = OrderActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> rejectAmendment(int orderId, int amendmentId) async {
    state = const OrderActionInProgress();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(orderRepositoryProvider).rejectAmendment(orderId, amendmentId),
          );
      state = const OrderActionSuccess();
    } on DioException catch (e) {
      state = OrderActionFailed(mapDioErrorToFailure(e));
    }
  }
}
