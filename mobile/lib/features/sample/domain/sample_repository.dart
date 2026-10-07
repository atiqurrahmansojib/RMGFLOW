import 'sample.dart';

/// Document 12.2: domain contract for /api/v1/samples and its nested
/// /revisions sub-resource (Doc 9.3/10.5).
abstract class SampleRepository {
  Future<List<Sample>> list({SampleStatus? status, int page = 0, int size = 100});
  Future<Sample> get(int id);
  Future<Sample> create(SampleDraft draft);
  Future<List<SampleRevision>> listRevisions(int sampleId);
  Future<SampleRevision> createRevision(int sampleId, SampleRevisionDraft draft);
  Future<SampleRevision> syncStatusFromLatestApproval(int sampleId);
}
