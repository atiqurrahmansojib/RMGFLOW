import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/style_repository_impl.dart';
import '../domain/style.dart';

sealed class StyleFormState {
  const StyleFormState();
}

class StyleFormIdle extends StyleFormState {
  const StyleFormIdle();
}

class StyleFormSubmitting extends StyleFormState {
  const StyleFormSubmitting();
}

class StyleFormSuccess extends StyleFormState {
  const StyleFormSuccess(this.style);
  final Style style;
}

class StyleFormFailed extends StyleFormState {
  const StyleFormFailed(this.failure);
  final Failure failure;
}

final styleFormControllerProvider =
    StateNotifierProvider.autoDispose<StyleFormController, StyleFormState>((ref) {
  return StyleFormController(ref);
});

/// Document 7 (#30): create-only from the mobile UI for now — revisions (#31) and
/// the edit/compare screens are a follow-up, noted in mobile/README.md.
class StyleFormController extends StateNotifier<StyleFormState> {
  StyleFormController(this._ref) : super(const StyleFormIdle());

  final Ref _ref;

  Future<void> submit(StyleDraft draft) async {
    state = const StyleFormSubmitting();
    try {
      final style = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(styleRepositoryProvider).create(draft),
          );
      state = StyleFormSuccess(style);
    } on DioException catch (e) {
      state = StyleFormFailed(mapDioErrorToFailure(e));
    }
  }
}
