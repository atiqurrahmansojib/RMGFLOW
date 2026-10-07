import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../features/auth/application/auth_controller.dart';

/// Small read/write helpers for screens that talk to simple sub-resource
/// endpoints (contacts, certifications, candidates…) without a full
/// repository/controller stack. Every call goes through
/// [AuthController.callAuthorized] so a 401 still triggers one silent refresh.

Future<T> authorizedCall<T>(Ref ref, Future<T> Function(Dio dio) call) =>
    ref.read(authControllerProvider.notifier).callAuthorized(() => call(ref.read(apiDioProvider)));

Future<T> authorizedWidgetCall<T>(WidgetRef ref, Future<T> Function(Dio dio) call) =>
    ref.read(authControllerProvider.notifier).callAuthorized(() => call(ref.read(apiDioProvider)));

/// GET a JSON list (bare array or Spring `Page.content`) as maps.
Future<List<Map<String, dynamic>>> getJsonList(Ref ref, String path, {Map<String, dynamic>? query}) =>
    authorizedCall(ref, (dio) async {
      final data = (await dio.get(path, queryParameters: query)).data;
      final list = data is Map<String, dynamic> ? data['content'] as List : data as List;
      return list.cast<Map<String, dynamic>>();
    });
