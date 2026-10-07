// Live contract smoke test: runs every mobile repository's read calls (and the
// report exports) against a REAL backend, as each demo role, so any drift
// between the backend DTOs and the mobile fromJson parsing fails loudly.
//
// Skipped unless a backend is given, e.g. a backend started with DEMO_DATA=true:
//   flutter test test/live_api_smoke_test.dart \
//     --dart-define=LIVE_API_BASE_URL=http://localhost:8080/api/v1
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmgflow_mobile/features/activity/data/activity_repository_impl.dart';
import 'package:rmgflow_mobile/features/approval/data/approval_repository_impl.dart';
import 'package:rmgflow_mobile/features/approval/domain/approval.dart';
import 'package:rmgflow_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:rmgflow_mobile/features/buyers/data/buyer_repository_impl.dart';
import 'package:rmgflow_mobile/features/claim/data/claim_repository_impl.dart';
import 'package:rmgflow_mobile/features/costing/data/costing_repository_impl.dart';
import 'package:rmgflow_mobile/features/dashboard/data/my_day_repository.dart';
import 'package:rmgflow_mobile/features/document/data/commercial_document_repository_impl.dart';
import 'package:rmgflow_mobile/features/document/domain/commercial_document.dart';
import 'package:rmgflow_mobile/features/factories/data/factory_repository_impl.dart';
import 'package:rmgflow_mobile/features/financial/data/financial_repository_impl.dart';
import 'package:rmgflow_mobile/features/inquiries/data/inquiry_repository_impl.dart';
import 'package:rmgflow_mobile/features/notification/data/notification_repository_impl.dart';
import 'package:rmgflow_mobile/features/order/data/order_repository_impl.dart';
import 'package:rmgflow_mobile/features/order/domain/order.dart';
import 'package:rmgflow_mobile/features/production/data/production_repository_impl.dart';
import 'package:rmgflow_mobile/features/quality/data/quality_repository_impl.dart';
import 'package:rmgflow_mobile/features/quotation/data/quotation_repository_impl.dart';
import 'package:rmgflow_mobile/features/report/data/report_repository_impl.dart';
import 'package:rmgflow_mobile/features/report/domain/report.dart';
import 'package:rmgflow_mobile/features/sample/data/sample_repository_impl.dart';
import 'package:rmgflow_mobile/features/shipment/data/shipment_repository_impl.dart';
import 'package:rmgflow_mobile/features/styles/data/style_repository_impl.dart';
import 'package:rmgflow_mobile/features/ta/data/ta_milestone_repository_impl.dart';
import 'package:rmgflow_mobile/features/task/data/task_repository_impl.dart';

const _baseUrl = String.fromEnvironment('LIVE_API_BASE_URL');

const _demoUsers = [
  'demo.admin', 'owner', 'gm', 'sr.merch', 'jr.merch', 'sampling', 'production',
  'quality', 'commercial', 'accounts', 'factory.coord', 'viewer',
];

/// Runs [call]; a 403 is an expected RBAC outcome for some roles and is not a
/// failure — anything else (parse error, 4xx/5xx) is.
Future<void> _check(List<String> failures, String label, Future<void> Function() call) async {
  try {
    await call();
  } on DioException catch (e) {
    if (e.response?.statusCode != 403) failures.add('$label -> ${e.response?.statusCode} ${e.response?.data}');
  } catch (e) {
    failures.add('$label -> $e');
  }
}

void main() {
  test('every repository parses live backend responses for every demo role', () async {
    final failures = <String>[];
    for (final user in _demoUsers) {
      final tokens = await AuthRepositoryImpl(Dio(BaseOptions(baseUrl: _baseUrl)))
          .login(email: '$user@rmgflow.test', password: 'Demo@1234');
      final dio = Dio(BaseOptions(baseUrl: _baseUrl, headers: {'Authorization': 'Bearer ${tokens.accessToken}'}));
      String l(String what) => '$user: $what';

      final orders = OrderRepositoryImpl(dio);
      final orderList = await orders.list().catchError((Object _) => <Order>[]);
      final orderIds = orderList.map((o) => o.id).toList();

      await _check(failures, l('my day'), () => MyDayRepository(dio).fetch());
      await _check(failures, l('notifications'), () => NotificationRepositoryImpl(dio).myNotifications());
      await _check(failures, l('buyers'), () => BuyerRepositoryImpl(dio).list());
      await _check(failures, l('buyer 1'), () => BuyerRepositoryImpl(dio).get(1));
      await _check(failures, l('factories'), () => FactoryRepositoryImpl(dio).list());
      await _check(failures, l('inquiries'), () => InquiryRepositoryImpl(dio).list());
      await _check(failures, l('styles'), () => StyleRepositoryImpl(dio).list());
      await _check(failures, l('costings'), () => CostingRepositoryImpl(dio).list());
      await _check(failures, l('costing 1'), () => CostingRepositoryImpl(dio).get(1));
      await _check(failures, l('quotations'), () => QuotationRepositoryImpl(dio).list());
      await _check(failures, l('samples'), () => SampleRepositoryImpl(dio).list());
      await _check(failures, l('sample revisions'), () => SampleRepositoryImpl(dio).listRevisions(1));
      await _check(failures, l('approvals inbox'), () => ApprovalRepositoryImpl(dio).inbox());
      await _check(failures, l('approval history'),
          () => ApprovalRepositoryImpl(dio).history(targetType: ApprovalTargetType.costing, targetId: 2));
      await _check(failures, l('all claims'), () => ClaimRepositoryImpl(dio).listAll());
      await _check(failures, l('all receivables'), () => FinancialRepositoryImpl(dio).listAllReceivables());
      await _check(failures, l('all payables'), () => FinancialRepositoryImpl(dio).listAllPayables());
      await _check(failures, l('my tasks'), () => TaskRepositoryImpl(dio).myOpenTasks());
      await _check(failures, l('order tasks'), () => TaskRepositoryImpl(dio).listByEntity(entityType: 'Order', entityId: 2));
      await _check(failures, l('buyer activities'),
          () => ActivityRepositoryImpl(dio).list(entityType: 'Buyer', entityId: 1));
      await _check(failures, l('shipment documents'), () => CommercialDocumentRepositoryImpl(dio)
          .list(entityType: DocumentEntityType.shipment, entityId: 1));
      for (final id in orderIds) {
        await _check(failures, l('order $id'), () => orders.get(id));
        await _check(failures, l('amendments $id'), () => orders.listAmendments(id));
        await _check(failures, l('T&A $id'), () => TaMilestoneRepositoryImpl(dio).list(id));
        await _check(failures, l('production $id'), () => ProductionRepositoryImpl(dio).progress(id));
        await _check(failures, l('shipments $id'), () => ShipmentRepositoryImpl(dio).list(id));
        await _check(failures, l('claims $id'), () => ClaimRepositoryImpl(dio).listByOrder(id));
        await _check(failures, l('financials $id'), () => FinancialRepositoryImpl(dio).getFinancials(id));
        await _check(failures, l('receivables $id'), () => FinancialRepositoryImpl(dio).listReceivablesByOrder(id));
        await _check(failures, l('payables $id'), () => FinancialRepositoryImpl(dio).listPayablesByOrder(id));
        await _check(failures, l('inspections $id'), () async {
          final quality = QualityRepositoryImpl(dio);
          for (final inspection in await quality.listInspections(id)) {
            await quality.listCapaByInspection(inspection.id);
            for (final defect in await quality.listDefects(inspection.id)) {
              await quality.listCapaByDefect(defect.id);
            }
          }
        });
      }

      final reports = ReportRepositoryImpl(dio);
      await _check(failures, l('reports'), () async {
        for (final definition in await reports.list()) {
          await reports.run(definition.code, const {});
          for (final format in ReportExportFormat.values) {
            final file = await reports.export(definition.code, format, const {});
            if (file.bytes.isEmpty || !file.fileName.startsWith(definition.code)) {
              failures.add(l('export ${definition.code} ${format.name} -> ${file.fileName}'));
            }
          }
        }
      });
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  }, skip: _baseUrl.isEmpty ? 'Set --dart-define=LIVE_API_BASE_URL to run against a live backend' : false,
      timeout: const Timeout(Duration(minutes: 10)));
}
