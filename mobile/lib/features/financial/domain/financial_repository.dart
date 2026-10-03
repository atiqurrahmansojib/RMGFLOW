import 'financial.dart';

/// Document 12.2: domain contract for /api/v1/orders/{orderId}/financials,
/// /receivables, /payables, and the global /payment-records sink (Doc 9.10/9.12).
abstract class FinancialRepository {
  Future<OrderFinancials> getFinancials(int orderId);
  Future<OrderFinancials> upsertFinancials(int orderId, OrderFinancialsDraft draft);
  Future<List<Receivable>> listReceivablesByOrder(int orderId);
  Future<List<Receivable>> listAllReceivables();
  Future<Receivable> createReceivable(int orderId, ReceivableDraft draft);
  Future<List<Payable>> listPayablesByOrder(int orderId);
  Future<List<Payable>> listAllPayables();
  Future<Payable> createPayable(int orderId, PayableDraft draft);
  Future<void> recordPayment(PaymentRecordDraft draft);
}
