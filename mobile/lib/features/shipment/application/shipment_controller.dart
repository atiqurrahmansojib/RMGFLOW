import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/shipment_repository_impl.dart';
import '../domain/shipment.dart';

sealed class ShipmentListState {
  const ShipmentListState();
}

class ShipmentListLoading extends ShipmentListState {
  const ShipmentListLoading();
}

class ShipmentListLoaded extends ShipmentListState {
  const ShipmentListLoaded(this.shipments);
  final List<Shipment> shipments;
}

class ShipmentListError extends ShipmentListState {
  const ShipmentListError(this.failure);
  final Failure failure;
}

final shipmentListControllerProvider =
    StateNotifierProvider.autoDispose.family<ShipmentListController, ShipmentListState, int>((ref, orderId) {
  return ShipmentListController(ref, orderId)..load();
});

/// Document 7 (#65-66): one order's shipments, including partial shipments.
class ShipmentListController extends StateNotifier<ShipmentListState> {
  ShipmentListController(this._ref, this._orderId) : super(const ShipmentListLoading());

  final Ref _ref;
  final int _orderId;

  Future<void> load() async {
    state = const ShipmentListLoading();
    try {
      final shipments = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(shipmentRepositoryProvider).list(_orderId),
          );
      state = ShipmentListLoaded(shipments);
    } on DioException catch (e) {
      state = ShipmentListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class ShipmentFormState {
  const ShipmentFormState();
}

class ShipmentFormIdle extends ShipmentFormState {
  const ShipmentFormIdle();
}

class ShipmentFormSubmitting extends ShipmentFormState {
  const ShipmentFormSubmitting();
}

class ShipmentFormSuccess extends ShipmentFormState {
  const ShipmentFormSuccess(this.shipment);
  final Shipment shipment;
}

class ShipmentFormFailed extends ShipmentFormState {
  const ShipmentFormFailed(this.failure);
  final Failure failure;
}

final shipmentFormControllerProvider =
    StateNotifierProvider.autoDispose<ShipmentFormController, ShipmentFormState>((ref) {
  return ShipmentFormController(ref);
});

/// Document 9.7/9.8/9.11 #5: creation enforces the quality gate (overridable),
/// the shipment-never-exceeds-order-quantity gate (NO override exists), and
/// partial-shipment authorization — all server-side.
class ShipmentFormController extends StateNotifier<ShipmentFormState> {
  ShipmentFormController(this._ref) : super(const ShipmentFormIdle());

  final Ref _ref;

  Future<void> submit(int orderId, ShipmentDraft draft) async {
    state = const ShipmentFormSubmitting();
    try {
      final shipment = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(shipmentRepositoryProvider).create(orderId, draft),
          );
      state = ShipmentFormSuccess(shipment);
    } on DioException catch (e) {
      state = ShipmentFormFailed(mapDioErrorToFailure(e));
    }
  }
}

sealed class ShipmentStatusState {
  const ShipmentStatusState();
}

class ShipmentStatusIdle extends ShipmentStatusState {
  const ShipmentStatusIdle();
}

class ShipmentStatusUpdating extends ShipmentStatusState {
  const ShipmentStatusUpdating();
}

class ShipmentStatusSuccess extends ShipmentStatusState {
  const ShipmentStatusSuccess(this.shipment);
  final Shipment shipment;
}

class ShipmentStatusFailed extends ShipmentStatusState {
  const ShipmentStatusFailed(this.failure);
  final Failure failure;
}

final shipmentStatusControllerProvider =
    StateNotifierProvider.autoDispose<ShipmentStatusController, ShipmentStatusState>((ref) {
  return ShipmentStatusController(ref);
});

/// Document 7 (#66): BOOKED/IN_TRANSIT/DELIVERED/DELAYED status updates.
class ShipmentStatusController extends StateNotifier<ShipmentStatusState> {
  ShipmentStatusController(this._ref) : super(const ShipmentStatusIdle());

  final Ref _ref;

  Future<void> updateStatus(int orderId, int shipmentId, ShipmentStatus status) async {
    state = const ShipmentStatusUpdating();
    try {
      final shipment = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(shipmentRepositoryProvider).updateStatus(orderId, shipmentId, status),
          );
      state = ShipmentStatusSuccess(shipment);
    } on DioException catch (e) {
      state = ShipmentStatusFailed(mapDioErrorToFailure(e));
    }
  }
}
