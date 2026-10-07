import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../../buyers/data/buyer_repository_impl.dart';
import '../../factories/data/factory_repository_impl.dart';
import '../data/report_file_saver.dart';
import '../data/report_repository_impl.dart';
import '../domain/report.dart';

// ---------------------------------------------------------------------------
// Catalog (reports hub)
// ---------------------------------------------------------------------------

sealed class ReportCatalogState {
  const ReportCatalogState();
}

class ReportCatalogLoading extends ReportCatalogState {
  const ReportCatalogLoading();
}

class ReportCatalogLoaded extends ReportCatalogState {
  const ReportCatalogLoaded(this.reports);
  final List<ReportDefinition> reports;
}

class ReportCatalogError extends ReportCatalogState {
  const ReportCatalogError(this.failure);
  final Failure failure;
}

final reportCatalogControllerProvider =
    StateNotifierProvider.autoDispose<ReportCatalogController, ReportCatalogState>((ref) {
  return ReportCatalogController(ref)..load();
});

/// Document 14: the reports the current user may run (server filters by RBAC).
class ReportCatalogController extends StateNotifier<ReportCatalogState> {
  ReportCatalogController(this._ref) : super(const ReportCatalogLoading());

  final Ref _ref;

  Future<void> load() async {
    state = const ReportCatalogLoading();
    try {
      final reports = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(reportRepositoryProvider).list(),
          );
      if (mounted) state = ReportCatalogLoaded(reports);
    } on DioException catch (e) {
      if (mounted) state = ReportCatalogError(mapDioErrorToFailure(e));
    }
  }

  Future<void> refresh() => load();
}

// ---------------------------------------------------------------------------
// One report's result
// ---------------------------------------------------------------------------

sealed class ReportResultState {
  const ReportResultState();
}

/// Nothing run yet — a required filter is still empty.
class ReportResultIdle extends ReportResultState {
  const ReportResultIdle();
}

class ReportResultLoading extends ReportResultState {
  const ReportResultLoading();
}

class ReportResultLoaded extends ReportResultState {
  const ReportResultLoaded(this.result);
  final ReportResult result;
}

class ReportResultError extends ReportResultState {
  const ReportResultError(this.failure);
  final Failure failure;
}

final reportResultControllerProvider =
    StateNotifierProvider.autoDispose.family<ReportResultController, ReportResultState, String>((ref, code) {
  return ReportResultController(ref, code);
});

class ReportResultController extends StateNotifier<ReportResultState> {
  ReportResultController(this._ref, this._code) : super(const ReportResultIdle());

  final Ref _ref;
  final String _code;

  Future<void> run(Map<String, String> filters) async {
    state = const ReportResultLoading();
    try {
      final result = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(reportRepositoryProvider).run(_code, filters),
          );
      if (mounted) state = ReportResultLoaded(result);
    } on DioException catch (e) {
      if (mounted) state = ReportResultError(mapDioErrorToFailure(e));
    }
  }
}

// ---------------------------------------------------------------------------
// Export (CSV / PDF download)
// ---------------------------------------------------------------------------

sealed class ReportExportState {
  const ReportExportState();
}

class ReportExportIdle extends ReportExportState {
  const ReportExportIdle();
}

class ReportExportInProgress extends ReportExportState {
  const ReportExportInProgress(this.format);
  final ReportExportFormat format;
}

class ReportExportSuccess extends ReportExportState {
  const ReportExportSuccess(this.file);
  final SavedReportFile file;
}

class ReportExportFailed extends ReportExportState {
  const ReportExportFailed(this.failure);
  final Failure failure;
}

final reportExportControllerProvider =
    StateNotifierProvider.autoDispose.family<ReportExportController, ReportExportState, String>((ref, code) {
  return ReportExportController(ref, code);
});

class ReportExportController extends StateNotifier<ReportExportState> {
  ReportExportController(this._ref, this._code) : super(const ReportExportIdle());

  final Ref _ref;
  final String _code;

  Future<void> download(ReportExportFormat format, Map<String, String> filters) async {
    if (state is ReportExportInProgress) return;
    state = ReportExportInProgress(format);
    try {
      final export = await _ref.read(authControllerProvider.notifier).callAuthorized(
            () => _ref.read(reportRepositoryProvider).export(_code, format, filters),
          );
      final saved = await _ref.read(reportFileSaverProvider).save(export);
      if (mounted) state = ReportExportSuccess(saved);
    } on DioException catch (e) {
      if (mounted) state = ReportExportFailed(mapDioErrorToFailure(e));
    } catch (_) {
      if (mounted) state = const ReportExportFailed(UnknownFailure('Could not save the file on this device.'));
    }
  }

  void reset() => state = const ReportExportIdle();
}

// ---------------------------------------------------------------------------
// Filter choices (buyer / factory dropdowns)
// ---------------------------------------------------------------------------

/// An id/label pair for a buyer or factory filter dropdown.
class ReportChoice {
  const ReportChoice(this.id, this.label);
  final int id;
  final String label;
}

final reportBuyerChoicesProvider = FutureProvider.autoDispose<List<ReportChoice>>((ref) async {
  final buyers = await ref.read(authControllerProvider.notifier).callAuthorized(
        () => ref.read(buyerRepositoryProvider).list(size: 500),
      );
  return buyers.map((b) => ReportChoice(b.id, '${b.name} (${b.code})')).toList()
    ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
});

final reportFactoryChoicesProvider = FutureProvider.autoDispose<List<ReportChoice>>((ref) async {
  final factories = await ref.read(authControllerProvider.notifier).callAuthorized(
        () => ref.read(factoryRepositoryProvider).list(),
      );
  return factories.map((f) => ReportChoice(f.id, '${f.name} (${f.code})')).toList()
    ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
});
