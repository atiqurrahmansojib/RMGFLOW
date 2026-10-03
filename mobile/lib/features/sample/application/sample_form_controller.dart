import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/sample_repository_impl.dart';
import '../domain/sample.dart';

sealed class SampleFormState {
  const SampleFormState();
}

class SampleFormIdle extends SampleFormState {
  const SampleFormIdle();
}

class SampleFormSubmitting extends SampleFormState {
  const SampleFormSubmitting();
}

class SampleFormSuccess extends SampleFormState {
  const SampleFormSuccess(this.sample);
  final Sample sample;
}

class SampleFormFailed extends SampleFormState {
  const SampleFormFailed(this.failure);
  final Failure failure;
}

final sampleFormControllerProvider =
    StateNotifierProvider.autoDispose<SampleFormController, SampleFormState>((ref) {
  return SampleFormController(ref);
});

/// Document 7 (#32): create a sample request — no edit endpoint exists
/// server-side (a mis-requested sample is superseded by a new one, Doc 9.3).
class SampleFormController extends StateNotifier<SampleFormState> {
  SampleFormController(this._ref) : super(const SampleFormIdle());

  final Ref _ref;

  Future<void> submit(SampleDraft draft) async {
    state = const SampleFormSubmitting();
    try {
      final sample = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(sampleRepositoryProvider).create(draft),
          );
      state = SampleFormSuccess(sample);
    } on DioException catch (e) {
      state = SampleFormFailed(mapDioErrorToFailure(e));
    }
  }
}

sealed class SampleRevisionFormState {
  const SampleRevisionFormState();
}

class SampleRevisionFormIdle extends SampleRevisionFormState {
  const SampleRevisionFormIdle();
}

class SampleRevisionFormSubmitting extends SampleRevisionFormState {
  const SampleRevisionFormSubmitting();
}

class SampleRevisionFormSuccess extends SampleRevisionFormState {
  const SampleRevisionFormSuccess(this.revision);
  final SampleRevision revision;
}

class SampleRevisionFormFailed extends SampleRevisionFormState {
  const SampleRevisionFormFailed(this.failure);
  final Failure failure;
}

final sampleRevisionFormControllerProvider =
    StateNotifierProvider.autoDispose<SampleRevisionFormController, SampleRevisionFormState>((ref) {
  return SampleRevisionFormController(ref);
});

/// Document 9.3/10.5: a new revision is always a new row (append-only); the
/// backend auto-submits it to the shared Approval Engine on create (no
/// separate submit step here). Once that round is decided (via the generic
/// `approval` feature's decide screen), call `syncStatusFromLatestApproval`
/// to roll the decision up onto the sample's `currentStatus`.
class SampleRevisionFormController extends StateNotifier<SampleRevisionFormState> {
  SampleRevisionFormController(this._ref) : super(const SampleRevisionFormIdle());

  final Ref _ref;

  Future<void> submit(int sampleId, SampleRevisionDraft draft) async {
    state = const SampleRevisionFormSubmitting();
    try {
      final revision = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(sampleRepositoryProvider).createRevision(sampleId, draft),
          );
      state = SampleRevisionFormSuccess(revision);
    } on DioException catch (e) {
      state = SampleRevisionFormFailed(mapDioErrorToFailure(e));
    }
  }
}
