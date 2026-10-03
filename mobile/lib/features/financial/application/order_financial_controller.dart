import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/financial_repository_impl.dart';
import '../domain/financial.dart';

typedef OrderFinancialSnapshot = ({OrderFinancials financials, List<Receivable> receivables, List<Payable> payables});

sealed class OrderFinancialState {
  const OrderFinancialState();
}

class OrderFinancialLoading extends OrderFinancialState {
  const OrderFinancialLoading();
}

class OrderFinancialLoaded extends OrderFinancialState {
  const OrderFinancialLoaded(this.snapshot);
  final OrderFinancialSnapshot snapshot;
}

class OrderFinancialError extends OrderFinancialState {
  const OrderFinancialError(this.failure);
  final Failure failure;
}

final orderFinancialControllerProvider =
    StateNotifierProvider.autoDispose.family<OrderFinancialController, OrderFinancialState, int>((ref, orderId) {
  return OrderFinancialController(ref, orderId)..load();
});

/// Document 7 (#70-72)/9.10/9.12: one order's financial picture — margin
/// (estimate vs realized), receivables, and payables, all server-derived.
class OrderFinancialController extends StateNotifier<OrderFinancialState> {
  OrderFinancialController(this._ref, this._orderId) : super(const OrderFinancialLoading());

  final Ref _ref;
  final int _orderId;

  Future<void> load() async {
    state = const OrderFinancialLoading();
    try {
      final repo = _ref.read(financialRepositoryProvider);
      final snapshot = await _ref.read(authControllerProvider.notifier).callAuthorized(() async {
        final financials = await repo.getFinancials(_orderId);
        final receivables = await repo.listReceivablesByOrder(_orderId);
        final payables = await repo.listPayablesByOrder(_orderId);
        return (financials: financials, receivables: receivables, payables: payables);
      });
      state = OrderFinancialLoaded(snapshot);
    } on DioException catch (e) {
      state = OrderFinancialError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class FinancialActionState {
  const FinancialActionState();
}

class FinancialActionIdle extends FinancialActionState {
  const FinancialActionIdle();
}

class FinancialActionInProgress extends FinancialActionState {
  const FinancialActionInProgress();
}

class FinancialActionSuccess extends FinancialActionState {
  const FinancialActionSuccess();
}

class FinancialActionFailed extends FinancialActionState {
  const FinancialActionFailed(this.failure);
  final Failure failure;
}

final financialActionControllerProvider =
    StateNotifierProvider.autoDispose<FinancialActionController, FinancialActionState>((ref) {
  return FinancialActionController(ref);
});

/// Document 9.10/9.12: upsert order financials (quoted/actual/realized unit
/// price — margin itself is never client-supplied), create receivables/
/// payables, and record payments (atomic write + balance update server-side).
class FinancialActionController extends StateNotifier<FinancialActionState> {
  FinancialActionController(this._ref) : super(const FinancialActionIdle());

  final Ref _ref;

  Future<void> upsertFinancials(int orderId, OrderFinancialsDraft draft) async {
    state = const FinancialActionInProgress();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(financialRepositoryProvider).upsertFinancials(orderId, draft),
          );
      state = const FinancialActionSuccess();
    } on DioException catch (e) {
      state = FinancialActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> createReceivable(int orderId, ReceivableDraft draft) async {
    state = const FinancialActionInProgress();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(financialRepositoryProvider).createReceivable(orderId, draft),
          );
      state = const FinancialActionSuccess();
    } on DioException catch (e) {
      state = FinancialActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> createPayable(int orderId, PayableDraft draft) async {
    state = const FinancialActionInProgress();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(financialRepositoryProvider).createPayable(orderId, draft),
          );
      state = const FinancialActionSuccess();
    } on DioException catch (e) {
      state = FinancialActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> recordPayment(PaymentRecordDraft draft) async {
    state = const FinancialActionInProgress();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(financialRepositoryProvider).recordPayment(draft),
          );
      state = const FinancialActionSuccess();
    } on DioException catch (e) {
      state = FinancialActionFailed(mapDioErrorToFailure(e));
    }
  }
}
