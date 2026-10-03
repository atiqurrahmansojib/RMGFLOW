import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/claim_repository_impl.dart';
import '../domain/claim.dart';

sealed class ClaimListState {
  const ClaimListState();
}

class ClaimListLoading extends ClaimListState {
  const ClaimListLoading();
}

class ClaimListLoaded extends ClaimListState {
  const ClaimListLoaded(this.claims);
  final List<Claim> claims;
}

class ClaimListError extends ClaimListState {
  const ClaimListError(this.failure);
  final Failure failure;
}

final claimListControllerProvider =
    StateNotifierProvider.autoDispose.family<ClaimListController, ClaimListState, int>((ref, orderId) {
  return ClaimListController(ref, orderId)..load();
});

/// Document 7 (#73-74)/6.3: claims for one order — ClaimService is
/// deliberately isolated from Order/Shipment mutation (tracking only).
class ClaimListController extends StateNotifier<ClaimListState> {
  ClaimListController(this._ref, this._orderId) : super(const ClaimListLoading());

  final Ref _ref;
  final int _orderId;

  Future<void> load() async {
    state = const ClaimListLoading();
    try {
      final claims = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(claimRepositoryProvider).listByOrder(_orderId),
          );
      state = ClaimListLoaded(claims);
    } on DioException catch (e) {
      state = ClaimListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class ClaimActionState {
  const ClaimActionState();
}

class ClaimActionIdle extends ClaimActionState {
  const ClaimActionIdle();
}

class ClaimActionInProgress extends ClaimActionState {
  const ClaimActionInProgress();
}

class ClaimActionSuccess extends ClaimActionState {
  const ClaimActionSuccess();
}

class ClaimActionFailed extends ClaimActionState {
  const ClaimActionFailed(this.failure);
  final Failure failure;
}

final claimActionControllerProvider =
    StateNotifierProvider.autoDispose<ClaimActionController, ClaimActionState>((ref) {
  return ClaimActionController(ref);
});

/// Document 7 (#74): raise and resolve claims.
class ClaimActionController extends StateNotifier<ClaimActionState> {
  ClaimActionController(this._ref) : super(const ClaimActionIdle());

  final Ref _ref;

  Future<void> create(int orderId, ClaimDraft draft) async {
    state = const ClaimActionInProgress();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(claimRepositoryProvider).create(orderId, draft),
          );
      state = const ClaimActionSuccess();
    } on DioException catch (e) {
      state = ClaimActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> resolve(int id, ClaimResolutionDraft draft) async {
    state = const ClaimActionInProgress();
    try {
      await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(claimRepositoryProvider).resolve(id, draft),
          );
      state = const ClaimActionSuccess();
    } on DioException catch (e) {
      state = ClaimActionFailed(mapDioErrorToFailure(e));
    }
  }
}
