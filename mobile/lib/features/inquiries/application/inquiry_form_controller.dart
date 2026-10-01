import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/inquiry_repository_impl.dart';
import '../domain/inquiry.dart';

sealed class InquiryFormState {
  const InquiryFormState();
}

class InquiryFormIdle extends InquiryFormState {
  const InquiryFormIdle();
}

class InquiryFormSubmitting extends InquiryFormState {
  const InquiryFormSubmitting();
}

class InquiryFormSuccess extends InquiryFormState {
  const InquiryFormSuccess(this.inquiry);
  final Inquiry inquiry;
}

class InquiryFormFailed extends InquiryFormState {
  const InquiryFormFailed(this.failure);
  final Failure failure;
}

final inquiryFormControllerProvider =
    StateNotifierProvider.autoDispose<InquiryFormController, InquiryFormState>((ref) {
  return InquiryFormController(ref);
});

class InquiryFormController extends StateNotifier<InquiryFormState> {
  InquiryFormController(this._ref) : super(const InquiryFormIdle());

  final Ref _ref;

  Future<void> submit({required InquiryDraft draft, int? existingId}) async {
    state = const InquiryFormSubmitting();
    try {
      final repo = _ref.read(inquiryRepositoryProvider);
      final inquiry = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => existingId == null ? repo.create(draft) : repo.update(existingId, draft),
          );
      state = InquiryFormSuccess(inquiry);
    } on DioException catch (e) {
      state = InquiryFormFailed(mapDioErrorToFailure(e));
    }
  }

  /// Document 7 (#27): the Mark Won/Lost/Hold/Quoted transition dialog action.
  Future<void> changeStatus(int id, InquiryStatus status, {String? lostReason}) async {
    state = const InquiryFormSubmitting();
    try {
      final inquiry = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(inquiryRepositoryProvider).changeStatus(id, status, lostReason: lostReason),
          );
      state = InquiryFormSuccess(inquiry);
    } on DioException catch (e) {
      state = InquiryFormFailed(mapDioErrorToFailure(e));
    }
  }
}
