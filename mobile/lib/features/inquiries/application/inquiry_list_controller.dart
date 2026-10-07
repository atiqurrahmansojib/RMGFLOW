import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/inquiry_repository_impl.dart';
import '../domain/inquiry.dart';

sealed class InquiryListState {
  const InquiryListState();
}

class InquiryListLoading extends InquiryListState {
  const InquiryListLoading();
}

class InquiryListLoaded extends InquiryListState {
  const InquiryListLoaded(this.inquiries);
  final List<Inquiry> inquiries;
}

class InquiryListError extends InquiryListState {
  const InquiryListError(this.failure);
  final Failure failure;
}

final inquiryListControllerProvider =
    StateNotifierProvider.autoDispose<InquiryListController, InquiryListState>((ref) {
  return InquiryListController(ref)..load();
});

/// Document 7 (#24): filterable by status, per Doc 14.2 ("Inquiry Pipeline").
class InquiryListController extends StateNotifier<InquiryListState> {
  InquiryListController(this._ref) : super(const InquiryListLoading());

  final Ref _ref;
  InquiryStatus? _filter;

  Future<void> load({InquiryStatus? status}) async {
    _filter = status ?? _filter;
    state = const InquiryListLoading();
    try {
      final inquiries = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(inquiryRepositoryProvider).list(status: _filter),
          );
      state = InquiryListLoaded(inquiries);
    } on DioException catch (e) {
      state = InquiryListError(mapDioErrorToFailure(e));
    }
  }

  /// Sets (or clears, with null) the status filter and reloads — `load`
  /// alone can't clear it because a null status means "keep current".
  Future<void> setFilter(InquiryStatus? status) {
    _filter = status;
    return load();
  }

  Future<void> refresh() => load();
}
