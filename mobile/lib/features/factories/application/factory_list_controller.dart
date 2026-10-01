import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/factory_repository_impl.dart';
import '../domain/factory.dart';

sealed class FactoryListState {
  const FactoryListState();
}

class FactoryListLoading extends FactoryListState {
  const FactoryListLoading();
}

class FactoryListLoaded extends FactoryListState {
  const FactoryListLoaded(this.factories);
  final List<Factory> factories;
}

class FactoryListError extends FactoryListState {
  const FactoryListError(this.failure);
  final Failure failure;
}

final factoryListControllerProvider =
    StateNotifierProvider.autoDispose<FactoryListController, FactoryListState>((ref) {
  return FactoryListController(ref)..load();
});

class FactoryListController extends StateNotifier<FactoryListState> {
  FactoryListController(this._ref) : super(const FactoryListLoading());

  final Ref _ref;
  PartnerType? _filter;

  Future<void> load({PartnerType? partnerType}) async {
    _filter = partnerType ?? _filter;
    state = const FactoryListLoading();
    try {
      final factories = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(factoryRepositoryProvider).list(partnerType: _filter),
          );
      state = FactoryListLoaded(factories);
    } on DioException catch (e) {
      state = FactoryListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}
