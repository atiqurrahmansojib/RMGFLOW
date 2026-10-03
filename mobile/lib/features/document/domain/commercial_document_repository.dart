import 'commercial_document.dart';

/// Document 12.2: domain contract for /api/v1/documents (Doc 8.9/10.4).
abstract class CommercialDocumentRepository {
  Future<List<CommercialDocument>> list({required DocumentEntityType entityType, required int entityId});
  Future<CommercialDocument> upload(CommercialDocumentDraft draft);
  Future<CommercialDocument> approve(int id);
}
