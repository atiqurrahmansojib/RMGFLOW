import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/order_repository_impl.dart';
import '../domain/order.dart';

sealed class OrderFormState {
  const OrderFormState();
}

class OrderFormIdle extends OrderFormState {
  const OrderFormIdle();
}

class OrderFormSubmitting extends OrderFormState {
  const OrderFormSubmitting();
}

class OrderFormSuccess extends OrderFormState {
  const OrderFormSuccess(this.order);
  final Order order;
}

class OrderFormFailed extends OrderFormState {
  const OrderFormFailed(this.failure);
  final Failure failure;
}

final orderFormControllerProvider =
    StateNotifierProvider.autoDispose<OrderFormController, OrderFormState>((ref) {
  return OrderFormController(ref);
});

/// Document 9.4: order creation enforces the factory-buyer-approval gate
/// server-side; a plain 400 here means the gate was hit without the override
/// flag — the form offers an "override" toggle + reason for permitted users,
/// the backend is still the real authorization check (ORDER_OVERRIDE_FACTORY_APPROVAL).
class OrderFormController extends StateNotifier<OrderFormState> {
  OrderFormController(this._ref) : super(const OrderFormIdle());

  final Ref _ref;

  Future<void> submit(OrderDraft draft) async {
    state = const OrderFormSubmitting();
    try {
      final order = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(orderRepositoryProvider).create(draft),
          );
      state = OrderFormSuccess(order);
    } on DioException catch (e) {
      state = OrderFormFailed(mapDioErrorToFailure(e));
    }
  }
}
