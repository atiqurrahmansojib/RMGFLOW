import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/commercial_document.dart';
import '../domain/commercial_document_repository.dart';

/// Document 11.2: talks to /api/v1/documents — requires DOCUMENT_VIEW/
/// DOCUMENT_MANAGE (Doc 5.2). Versioning is server-side (Doc 8.9): uploading
/// against an entityType/entityId/documentType that already has a document
/// creates version N+1, never overwrites.
class CommercialDocumentRepositoryImpl implements CommercialDocumentRepository {
  CommercialDocumentRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<CommercialDocument>> list({required DocumentEntityType entityType, required int entityId}) async {
    final response = await _dio.get('/documents', queryParameters: {
      'entityType': entityType.apiValue,
      'entityId': entityId,
    });
    return (response.data as List).map((e) => CommercialDocument.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CommercialDocument> upload(CommercialDocumentDraft draft) async {
    final response = await _dio.post('/documents', data: draft.toJson());
    return CommercialDocument.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CommercialDocument> approve(int id) async {
    final response = await _dio.post('/documents/$id/approve');
    return CommercialDocument.fromJson(response.data as Map<String, dynamic>);
  }
}

final commercialDocumentRepositoryProvider = Provider<CommercialDocumentRepository>((ref) {
  return CommercialDocumentRepositoryImpl(ref.watch(apiDioProvider));
});
