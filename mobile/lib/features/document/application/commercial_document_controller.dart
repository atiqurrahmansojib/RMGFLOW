import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/commercial_document_repository_impl.dart';
import '../domain/commercial_document.dart';

sealed class CommercialDocumentListState {
  const CommercialDocumentListState();
}

class CommercialDocumentListLoading extends CommercialDocumentListState {
  const CommercialDocumentListLoading();
}

class CommercialDocumentListLoaded extends CommercialDocumentListState {
  const CommercialDocumentListLoaded(this.documents);
  final List<CommercialDocument> documents;
}

class CommercialDocumentListError extends CommercialDocumentListState {
  const CommercialDocumentListError(this.failure);
  final Failure failure;
}

typedef DocumentTarget = ({DocumentEntityType entityType, int entityId});

final commercialDocumentListControllerProvider = StateNotifierProvider.autoDispose
    .family<CommercialDocumentListController, CommercialDocumentListState, DocumentTarget>((ref, target) {
  return CommercialDocumentListController(ref, target)..load();
});

/// Document 7 (#46-47)/8.9/10.4: versioned commercial documents for one
/// polymorphic target (order/shipment/factory/style).
class CommercialDocumentListController extends StateNotifier<CommercialDocumentListState> {
  CommercialDocumentListController(this._ref, this._target) : super(const CommercialDocumentListLoading());

  final Ref _ref;
  final DocumentTarget _target;

  Future<void> load() async {
    state = const CommercialDocumentListLoading();
    try {
      final documents = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(commercialDocumentRepositoryProvider).list(
                  entityType: _target.entityType,
                  entityId: _target.entityId,
                ),
          );
      state = CommercialDocumentListLoaded(documents);
    } on DioException catch (e) {
      state = CommercialDocumentListError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

sealed class CommercialDocumentActionState {
  const CommercialDocumentActionState();
}

class CommercialDocumentActionIdle extends CommercialDocumentActionState {
  const CommercialDocumentActionIdle();
}

class CommercialDocumentActionInProgress extends CommercialDocumentActionState {
  const CommercialDocumentActionInProgress();
}

class CommercialDocumentActionSuccess extends CommercialDocumentActionState {
  const CommercialDocumentActionSuccess(this.document);
  final CommercialDocument document;
}

class CommercialDocumentActionFailed extends CommercialDocumentActionState {
  const CommercialDocumentActionFailed(this.failure);
  final Failure failure;
}

final commercialDocumentActionControllerProvider =
    StateNotifierProvider.autoDispose<CommercialDocumentActionController, CommercialDocumentActionState>((ref) {
  return CommercialDocumentActionController(ref);
});

/// Document 8.9: upload always creates a new version, never overwrites.
class CommercialDocumentActionController extends StateNotifier<CommercialDocumentActionState> {
  CommercialDocumentActionController(this._ref) : super(const CommercialDocumentActionIdle());

  final Ref _ref;

  Future<void> upload(CommercialDocumentDraft draft) async {
    state = const CommercialDocumentActionInProgress();
    try {
      final document = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(commercialDocumentRepositoryProvider).upload(draft),
          );
      state = CommercialDocumentActionSuccess(document);
    } on DioException catch (e) {
      state = CommercialDocumentActionFailed(mapDioErrorToFailure(e));
    }
  }

  Future<void> approve(int id) async {
    state = const CommercialDocumentActionInProgress();
    try {
      final document = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(commercialDocumentRepositoryProvider).approve(id),
          );
      state = CommercialDocumentActionSuccess(document);
    } on DioException catch (e) {
      state = CommercialDocumentActionFailed(mapDioErrorToFailure(e));
    }
  }
}
