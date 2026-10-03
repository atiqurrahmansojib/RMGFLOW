import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/sample_repository_impl.dart';
import '../domain/sample.dart';

sealed class SampleListState {
  const SampleListState();
}

class SampleListLoading extends SampleListState {
  const SampleListLoading();
}

class SampleListLoaded extends SampleListState {
  const SampleListLoaded(this.samples);
  final List<Sample> samples;
}

class SampleListError extends SampleListState {
  const SampleListError(this.failure);
  final Failure failure;
}

final sampleListControllerProvider =
    StateNotifierProvider.autoDispose<SampleListController, SampleListState>((ref) {
  return SampleListController(ref)..load();
});

/// Document 7 (#32): sample list, optionally filtered by status.
class SampleListController extends StateNotifier<SampleListState> {
  SampleListController(this._ref) : super(const SampleListLoading());

  final Ref _ref;
  SampleStatus? _status;

  Future<void> load({SampleStatus? status}) async {
    _status = status;
    state = const SampleListLoading();
    try {
      final samples = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(sampleRepositoryProvider).list(status: _status),
          );
      state = SampleListLoaded(samples);
    } on DioException catch (e) {
      state = SampleListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load(status: _status);
}
