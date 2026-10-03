import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/quality.dart';
import '../domain/quality_repository.dart';

/// Document 11.2: talks to /api/v1/orders/{orderId}/inspections(/defects) and
/// /api/v1/capa-records — requires QUALITY_VIEW/QUALITY_MANAGE (Doc 5.2).
class QualityRepositoryImpl implements QualityRepository {
  QualityRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Inspection>> listInspections(int orderId) async {
    final response = await _dio.get('/orders/$orderId/inspections');
    return (response.data as List).map((e) => Inspection.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Inspection> createInspection(int orderId, InspectionDraft draft) async {
    final response = await _dio.post('/orders/$orderId/inspections', data: draft.toJson());
    return Inspection.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<Defect>> listDefects(int inspectionId) async {
    final response = await _dio.get('/inspections/$inspectionId/defects');
    return (response.data as List).map((e) => Defect.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Defect> createDefect(int inspectionId, DefectDraft draft) async {
    final response = await _dio.post('/inspections/$inspectionId/defects', data: draft.toJson());
    return Defect.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<CapaRecord>> listCapaByDefect(int defectId) async {
    final response = await _dio.get('/capa-records', queryParameters: {'defectId': defectId});
    return (response.data as List).map((e) => CapaRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CapaRecord>> listCapaByInspection(int inspectionId) async {
    final response = await _dio.get('/capa-records', queryParameters: {'inspectionId': inspectionId});
    return (response.data as List).map((e) => CapaRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CapaRecord> createCapa(CapaRecordDraft draft) async {
    final response = await _dio.post('/capa-records', data: draft.toJson());
    return CapaRecord.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CapaRecord> recordFactoryResponse(int capaId, String factoryResponse) async {
    final response = await _dio.post('/capa-records/$capaId/factory-response', data: {'factoryResponse': factoryResponse});
    return CapaRecord.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CapaRecord> closeCapa(int capaId) async {
    final response = await _dio.post('/capa-records/$capaId/close');
    return CapaRecord.fromJson(response.data as Map<String, dynamic>);
  }
}

final qualityRepositoryProvider = Provider<QualityRepository>((ref) {
  return QualityRepositoryImpl(ref.watch(apiDioProvider));
});
