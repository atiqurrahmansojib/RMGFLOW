import 'quality.dart';

/// Document 12.2: domain contract for /api/v1/orders/{orderId}/inspections,
/// nested /defects, and /api/v1/capa-records (Doc 9.7-9.9).
abstract class QualityRepository {
  Future<List<Inspection>> listInspections(int orderId);
  Future<Inspection> createInspection(int orderId, InspectionDraft draft);
  Future<List<Defect>> listDefects(int inspectionId);
  Future<Defect> createDefect(int inspectionId, DefectDraft draft);
  Future<List<CapaRecord>> listCapaByDefect(int defectId);
  Future<List<CapaRecord>> listCapaByInspection(int inspectionId);
  Future<CapaRecord> createCapa(CapaRecordDraft draft);
  Future<CapaRecord> recordFactoryResponse(int capaId, String factoryResponse);
  Future<CapaRecord> closeCapa(int capaId);
}
