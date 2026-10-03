import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/my_day_repository.dart';
import '../domain/my_day.dart';

sealed class MyDayState {
  const MyDayState();
}

class MyDayLoading extends MyDayState {
  const MyDayLoading();
}

class MyDayLoaded extends MyDayState {
  const MyDayLoaded(this.myDay);
  final MyDay myDay;
}

class MyDayError extends MyDayState {
  const MyDayError(this.failure);
  final Failure failure;
}

final myDayControllerProvider = StateNotifierProvider.autoDispose<MyDayController, MyDayState>((ref) {
  return MyDayController(ref)..load();
});

/// Document 14.9: the recommended post-login landing view — "what needs
/// attention today" aggregated across T&A/approvals/tasks in one call.
class MyDayController extends StateNotifier<MyDayState> {
  MyDayController(this._ref) : super(const MyDayLoading());

  final Ref _ref;

  Future<void> load() async {
    state = const MyDayLoading();
    try {
      final myDay = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(myDayRepositoryProvider).fetch(),
          );
      state = MyDayLoaded(myDay);
    } on DioException catch (e) {
      state = MyDayError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}
