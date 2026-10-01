import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/buyer_repository_impl.dart';
import '../domain/buyer.dart';

sealed class BuyerListState {
  const BuyerListState();
}

class BuyerListLoading extends BuyerListState {
  const BuyerListLoading();
}

class BuyerListLoaded extends BuyerListState {
  const BuyerListLoaded(this.buyers);
  final List<Buyer> buyers;
}

class BuyerListError extends BuyerListState {
  const BuyerListError(this.failure);
  final Failure failure;
}

final buyerListControllerProvider =
    StateNotifierProvider.autoDispose<BuyerListController, BuyerListState>((ref) {
  return BuyerListController(ref)..load();
});

/// Document 7 (#16): search-driven list, per Doc 35 ("search-driven, minimal-click").
class BuyerListController extends StateNotifier<BuyerListState> {
  BuyerListController(this._ref) : super(const BuyerListLoading());

  final Ref _ref;
  String _search = '';

  Future<void> load({String? search}) async {
    if (search != null) _search = search;
    state = const BuyerListLoading();
    try {
      final buyers = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(buyerRepositoryProvider).list(search: _search),
          );
      state = BuyerListLoaded(buyers);
    } on DioException catch (e) {
      state = BuyerListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}
