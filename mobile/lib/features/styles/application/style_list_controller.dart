import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/style_repository_impl.dart';
import '../domain/style.dart';

sealed class StyleListState {
  const StyleListState();
}

class StyleListLoading extends StyleListState {
  const StyleListLoading();
}

class StyleListLoaded extends StyleListState {
  const StyleListLoaded(this.styles);
  final List<Style> styles;
}

class StyleListError extends StyleListState {
  const StyleListError(this.failure);
  final Failure failure;
}

final styleListControllerProvider =
    StateNotifierProvider.autoDispose<StyleListController, StyleListState>((ref) {
  return StyleListController(ref)..load();
});

class StyleListController extends StateNotifier<StyleListState> {
  StyleListController(this._ref) : super(const StyleListLoading());

  final Ref _ref;
  String _search = '';

  Future<void> load({String? search}) async {
    if (search != null) _search = search;
    state = const StyleListLoading();
    try {
      final styles = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(styleRepositoryProvider).list(search: _search),
          );
      state = StyleListLoaded(styles);
    } on DioException catch (e) {
      state = StyleListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}
