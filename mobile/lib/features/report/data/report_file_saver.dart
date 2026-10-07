import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/report.dart';

/// Where a downloaded report ended up. [localPath] is always an app-private
/// copy (used for Open/Share); [publicLocation] is the user-visible location
/// (e.g. "Download/RMGFlow/order-status-20261006.pdf") or null when the
/// public copy could not be written.
class SavedReportFile {
  const SavedReportFile({
    required this.fileName,
    required this.localPath,
    required this.mimeType,
    this.publicLocation,
  });

  final String fileName;
  final String localPath;
  final String mimeType;
  final String? publicLocation;
}

abstract class ReportFileSaver {
  Future<SavedReportFile> save(ReportExport export);
}

/// Android: copies the export into the shared Download/RMGFlow folder via
/// a platform channel (MainActivity). API 29+ uses MediaStore (scoped
/// storage, no permission); API 28 and below writes directly and needs
/// WRITE_EXTERNAL_STORAGE (manifest declares it with maxSdkVersion=28).
/// Other platforms: app documents directory only.
class DeviceReportFileSaver implements ReportFileSaver {
  static const _channel = MethodChannel('com.rmgflow/downloads');

  @override
  Future<SavedReportFile> save(ReportExport export) async {
    final baseDir = Platform.isAndroid ? await getTemporaryDirectory() : await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${baseDir.path}/reports');
    await reportsDir.create(recursive: true);
    final local = File('${reportsDir.path}/${export.fileName}');
    await local.writeAsBytes(export.bytes, flush: true);

    String? publicLocation;
    if (Platform.isAndroid) {
      publicLocation = await _saveToDownloads(local, export);
    }

    return SavedReportFile(
      fileName: export.fileName,
      localPath: local.path,
      mimeType: export.format.mimeType,
      publicLocation: publicLocation,
    );
  }

  Future<String?> _saveToDownloads(File local, ReportExport export, {bool retried = false}) async {
    try {
      return await _channel.invokeMethod<String>('saveToDownloads', {
        'sourcePath': local.path,
        'fileName': export.fileName,
        'mimeType': export.format.mimeType,
      });
    } on PlatformException catch (e) {
      if (e.code == 'permission_required' && !retried) {
        final status = await Permission.storage.request();
        if (status.isGranted) return _saveToDownloads(local, export, retried: true);
      }
      // The in-app copy is still usable via Open/Share; the UI says so.
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

final reportFileSaverProvider = Provider<ReportFileSaver>((ref) => DeviceReportFileSaver());
