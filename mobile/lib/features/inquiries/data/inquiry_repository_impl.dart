import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/inquiry.dart';
import '../domain/inquiry_repository.dart';

class InquiryRepositoryImpl implements InquiryRepository {
  InquiryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Inquiry>> list({InquiryStatus? status}) async {
    final response = await _dio.get('/inquiries', queryParameters: {
      if (status != null) 'status': status.apiValue,
      // Spring's default page is 20 rows; load enough for search, newest first.
      'size': 100,
      'sort': 'id,desc',
    });
    final content = (response.data as Map<String, dynamic>)['content'] as List;
    return content.map((e) => Inquiry.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Inquiry> create(InquiryDraft draft) async {
    final response = await _dio.post('/inquiries', data: draft.toJson());
    return Inquiry.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Inquiry> update(int id, InquiryDraft draft) async {
    final response = await _dio.put('/inquiries/$id', data: draft.toJson());
    return Inquiry.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Inquiry> changeStatus(int id, InquiryStatus status, {String? lostReason}) async {
    final response = await _dio.post('/inquiries/$id/status', data: {
      'status': status.apiValue,
      'lostReason': lostReason,
    });
    return Inquiry.fromJson(response.data as Map<String, dynamic>);
  }
}

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return InquiryRepositoryImpl(ref.watch(apiDioProvider));
});
