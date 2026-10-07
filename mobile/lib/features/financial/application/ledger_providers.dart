import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/financial_repository_impl.dart';
import '../domain/financial.dart';

/// Document 7 (#78/#79): organization-wide receivables and payables, across
/// every order — the accounts view, as opposed to one order's financials.
final allReceivablesProvider = FutureProvider.autoDispose<List<Receivable>>((ref) {
  return ref
      .read(authControllerProvider.notifier)
      .callAuthorized(() => ref.read(financialRepositoryProvider).listAllReceivables());
});

final allPayablesProvider = FutureProvider.autoDispose<List<Payable>>((ref) {
  return ref
      .read(authControllerProvider.notifier)
      .callAuthorized(() => ref.read(financialRepositoryProvider).listAllPayables());
});
