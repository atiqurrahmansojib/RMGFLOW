import 'inquiry.dart';

abstract class InquiryRepository {
  Future<List<Inquiry>> list({InquiryStatus? status});
  Future<Inquiry> create(InquiryDraft draft);
  Future<Inquiry> update(int id, InquiryDraft draft);
  Future<Inquiry> changeStatus(int id, InquiryStatus status, {String? lostReason});
}
