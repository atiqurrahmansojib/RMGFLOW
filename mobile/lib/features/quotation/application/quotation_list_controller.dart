import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/quotation_repository_impl.dart';
import '../domain/quotation.dart';

sealed class QuotationListState {
  const QuotationListState();
}

class QuotationListLoading extends QuotationListState {
  const QuotationListLoading();
}

class QuotationListLoaded extends QuotationListState {
  const QuotationListLoaded(this.quotations);
  final List<Quotation> quotations;
}

class QuotationListError extends QuotationListState {
  const QuotationListError(this.failure);
  final Failure failure;
}

final quotationListControllerProvider =
    StateNotifierProvider.autoDispose<QuotationListController, QuotationListState>((ref) {
  return QuotationListController(ref)..load();
});

/// Document 7 (#40-42): quotation list, optionally filtered by buyer.
class QuotationListController extends StateNotifier<QuotationListState> {
  QuotationListController(this._ref) : super(const QuotationListLoading());

  final Ref _ref;
  int? _buyerId;

  Future<void> load({int? buyerId}) async {
    if (buyerId != null) _buyerId = buyerId;
    state = const QuotationListLoading();
    try {
      final quotations = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(quotationRepositoryProvider).list(buyerId: _buyerId),
          );
      state = QuotationListLoaded(quotations);
    } on DioException catch (e) {
      state = QuotationListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}
