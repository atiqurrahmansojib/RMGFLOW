import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/factory_repository_impl.dart';
import '../domain/factory.dart';

sealed class FactoryFormState {
  const FactoryFormState();
}

class FactoryFormIdle extends FactoryFormState {
  const FactoryFormIdle();
}

class FactoryFormSubmitting extends FactoryFormState {
  const FactoryFormSubmitting();
}

class FactoryFormSuccess extends FactoryFormState {
  const FactoryFormSuccess(this.factory);
  final Factory factory;
}

class FactoryFormFailed extends FactoryFormState {
  const FactoryFormFailed(this.failure);
  final Failure failure;
}

final factoryFormControllerProvider =
    StateNotifierProvider.autoDispose<FactoryFormController, FactoryFormState>((ref) {
  return FactoryFormController(ref);
});

class FactoryFormController extends StateNotifier<FactoryFormState> {
  FactoryFormController(this._ref) : super(const FactoryFormIdle());

  final Ref _ref;

  Future<void> submit({required FactoryDraft draft, int? existingId}) async {
    state = const FactoryFormSubmitting();
    try {
      final repo = _ref.read(factoryRepositoryProvider);
      final factory = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => existingId == null ? repo.create(draft) : repo.update(existingId, draft),
          );
      state = FactoryFormSuccess(factory);
    } on DioException catch (e) {
      state = FactoryFormFailed(mapDioErrorToFailure(e));
    }
  }
}
