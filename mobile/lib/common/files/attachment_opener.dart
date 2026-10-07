import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/network/failure_mapper.dart';
import '../lookups/api_helpers.dart';
import '../widgets/feedback.dart';

/// Document 7 (#76)/15.4: download an attachment through its short-lived
/// signed URL (`GET /attachments/{id}/url` → `/attachments/download?token=`),
/// keep an app-private copy, then open it in a viewer app — falling back to
/// the share sheet when nothing on the device can open that file type.
Future<void> openAttachment(BuildContext context, WidgetRef ref, int attachmentId, {String? fallbackName}) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Downloading file…'), duration: Duration(seconds: 20)));
  try {
    final file = await authorizedWidgetCall(ref, (dio) async {
      final signed = (await dio.get('/attachments/$attachmentId/url')).data as Map<String, dynamic>;
      // The signed path is server-absolute (/api/v1/...); resolve it against the API origin.
      final url = Uri.parse(AppConfig.apiBaseUrl).resolve(signed['url'] as String).toString();
      final response = await dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
      final name =
          (_fileName(response.headers.value('content-disposition')) ?? fallbackName ?? 'attachment-$attachmentId')
              .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final dir = Directory('${(await getTemporaryDirectory()).path}/attachments');
      await dir.create(recursive: true);
      final out = File('${dir.path}/$name');
      await out.writeAsBytes(Uint8List.fromList(response.data ?? const []), flush: true);
      return (path: out.path, type: response.headers.value('content-type'));
    });
    messenger.hideCurrentSnackBar();
    final result = await OpenFilex.open(file.path, type: file.type);
    if (result.type != ResultType.done) {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: file.type)]));
    }
  } on DioException catch (e) {
    messenger.hideCurrentSnackBar();
    if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
  } on FileSystemException {
    messenger.hideCurrentSnackBar();
    if (context.mounted) showErrorSnack(context, 'Could not save the file on this device.');
  }
}

String? _fileName(String? disposition) {
  if (disposition == null) return null;
  final match = RegExp(r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''', caseSensitive: false).firstMatch(disposition);
  final raw = match?.group(1)?.trim();
  if (raw == null || raw.isEmpty) return null;
  // Strip any path components a malicious header might carry.
  final name = Uri.decodeComponent(raw).split(RegExp(r'[\\/]')).last;
  return (name.isEmpty || name == '.' || name == '..') ? null : name;
}
