import 'package:dio/dio.dart';

import 'failure.dart';

/// Document 11.3/12.7: maps the backend's RFC 7807 Problem Details error shape
/// (or a transport-level Dio error) onto one Failure type. This is the ONLY
/// place that interprets raw HTTP status codes — screens never do.
Failure mapDioErrorToFailure(DioException error) {
  final response = error.response;
  if (response == null) {
    return const NetworkFailure();
  }

  final data = response.data;
  final detail = data is Map ? data['detail'] as String? : null;

  switch (response.statusCode) {
    case 400:
      final fieldErrors = data is Map && data['fieldErrors'] is List
          ? List<String>.from(data['fieldErrors'] as List)
          : const <String>[];
      return ValidationFailure(detail ?? 'Please check the highlighted fields.', fieldErrors: fieldErrors);
    case 401:
      return AuthFailure(detail ?? 'Your session has expired. Please sign in again.');
    case 403:
      return ForbiddenFailure(detail ?? "You don't have permission to do that.");
    case 409:
      return ConflictFailure(detail ?? 'This record changed elsewhere. Refresh and try again.');
    default:
      if ((response.statusCode ?? 0) >= 500) {
        return const ServerFailure();
      }
      return UnknownFailure(detail ?? 'Unexpected error.');
  }
}
