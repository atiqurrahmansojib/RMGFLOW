import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/ta_milestone_repository_impl.dart';
import '../domain/ta_milestone.dart';

sealed class TaMilestoneListState {
  const TaMilestoneListState();
}

class TaMilestoneListLoading extends TaMilestoneListState {
  const TaMilestoneListLoading();
}

class TaMilestoneListLoaded extends TaMilestoneListState {
  const TaMilestoneListLoaded(this.milestones);
  final List<TaMilestone> milestones;
}

class TaMilestoneListError extends TaMilestoneListState {
  const TaMilestoneListError(this.failure);
  final Failure failure;
}

final taMilestoneListControllerProvider =
    StateNotifierProvider.autoDispose.family<TaMilestoneListController, TaMilestoneListState, int>((ref, orderId) {
  return TaMilestoneListController(ref, orderId)..load();
});

/// Document 7 (#54): one order's T&A calendar, sorted by sequence.
class TaMilestoneListController extends StateNotifier<TaMilestoneListState> {
  TaMilestoneListController(this._ref, this._orderId) : super(const TaMilestoneListLoading());

  final Ref _ref;
  final int _orderId;

  Future<void> load() async {
    state = const TaMilestoneListLoading();
    try {
      final milestones = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(taMilestoneRepositoryProvider).list(_orderId),
          );
      state = TaMilestoneListLoaded(milestones);
    } on DioException catch (e) {
      state = TaMilestoneListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> generate(int styleId) async {
    state = const TaMilestoneListLoading();
    try {
      final milestones = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(taMilestoneRepositoryProvider).generate(_orderId, styleId),
          );
      state = TaMilestoneListLoaded(milestones);
    } on DioException catch (e) {
      state = TaMilestoneListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class TaMilestoneActionState {
  const TaMilestoneActionState();
}

class TaMilestoneActionIdle extends TaMilestoneActionState {
  const TaMilestoneActionIdle();
}

class TaMilestoneActionInProgress extends TaMilestoneActionState {
  const TaMilestoneActionInProgress();
}

class TaMilestoneActionSuccess extends TaMilestoneActionState {
  const TaMilestoneActionSuccess(this.milestone);
  final TaMilestone milestone;
}

class TaMilestoneActionFailed extends TaMilestoneActionState {
  const TaMilestoneActionFailed(this.failure);
  final Failure failure;
}

final taMilestoneActionControllerProvider =
    StateNotifierProvider.autoDispose<TaMilestoneActionController, TaMilestoneActionState>((ref) {
  return TaMilestoneActionController(ref);
});

/// Document A16: recording a late actual date triggers the server-side delay
/// cascade onto every dependent milestone — this screen never computes the
/// cascade itself, it only shows what comes back after.
class TaMilestoneActionController extends StateNotifier<TaMilestoneActionState> {
  TaMilestoneActionController(this._ref) : super(const TaMilestoneActionIdle());

  final Ref _ref;

  Future<void> recordActualDate(int orderId, int milestoneId, RecordActualDateDraft draft) async {
    state = const TaMilestoneActionInProgress();
    try {
      final milestone = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(taMilestoneRepositoryProvider).recordActualDate(orderId, milestoneId, draft),
          );
      state = TaMilestoneActionSuccess(milestone);
    } on DioException catch (e) {
      state = TaMilestoneActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> assignResponsibleUser(int orderId, int milestoneId, int userId) async {
    state = const TaMilestoneActionInProgress();
    try {
      final milestone = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(taMilestoneRepositoryProvider).assignResponsibleUser(orderId, milestoneId, userId),
          );
      state = TaMilestoneActionSuccess(milestone);
    } on DioException catch (e) {
      state = TaMilestoneActionFailed(mapDioErrorToFailure(e));
    }
  }
}
