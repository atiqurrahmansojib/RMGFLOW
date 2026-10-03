import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/order_repository_impl.dart';
import '../domain/order.dart';

sealed class OrderListState {
  const OrderListState();
}

class OrderListLoading extends OrderListState {
  const OrderListLoading();
}

class OrderListLoaded extends OrderListState {
  const OrderListLoaded(this.orders);
  final List<Order> orders;
}

class OrderListError extends OrderListState {
  const OrderListError(this.failure);
  final Failure failure;
}

final orderListControllerProvider =
    StateNotifierProvider.autoDispose<OrderListController, OrderListState>((ref) {
  return OrderListController(ref)..load();
});

/// Document 7 (#48-50): order list, optionally filtered by buyer/status.
class OrderListController extends StateNotifier<OrderListState> {
  OrderListController(this._ref) : super(const OrderListLoading());

  final Ref _ref;
  int? _buyerId;
  OrderStatus? _status;

  Future<void> load({int? buyerId, OrderStatus? status}) async {
    if (buyerId != null) _buyerId = buyerId;
    if (status != null) _status = status;
    state = const OrderListLoading();
    try {
      final orders = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(orderRepositoryProvider).list(buyerId: _buyerId, status: _status),
          );
      state = OrderListLoaded(orders);
    } on DioException catch (e) {
      state = OrderListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}
