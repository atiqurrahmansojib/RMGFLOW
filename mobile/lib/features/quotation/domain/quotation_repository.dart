import 'quotation.dart';

/// Document 12.2: domain contract for /api/v1/quotations (Doc 9.2).
abstract class QuotationRepository {
  Future<List<Quotation>> list({int? buyerId, int page = 0, int size = 25});
  Future<Quotation> get(int id);
  Future<Quotation> create(QuotationDraft draft);
  Future<Quotation> createRevision(int id, QuotationDraft draft);
  Future<Quotation> updateStatus(int id, QuotationStatus status);
}
