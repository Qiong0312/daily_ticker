import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/types.dart';
import 'storage.dart';

class BackupCancelled implements Exception {}

class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Anchor rect for the iOS/iPadOS share sheet (required on iPad).
///
/// Prefer a mounted [anchorContext] (e.g. the backup card). Must be captured
/// before removing/replacing that widget from the tree.
Rect shareOriginFromContext(BuildContext anchorContext) {
  final box = anchorContext.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    final origin = box.localToGlobal(Offset.zero) & box.size;
    if (origin.width > 0 && origin.height > 0) return origin;
  }
  final size = MediaQuery.sizeOf(anchorContext);
  // Fallback: bottom-center of the screen (valid non-zero rect for iPad popover).
  return Rect.fromLTWH(
    size.width * 0.25,
    size.height * 0.55,
    size.width * 0.5,
    44,
  );
}

/// Writes JSON to app documents and opens the system share sheet.
Future<void> exportProgressBackup(
  AppData data, {
  required Rect sharePositionOrigin,
}) async {
  final json = encodeAppData(data);
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/daily_ticker_backup.json');
  await file.writeAsString(json);
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(
          file.path,
          mimeType: 'application/json',
          name: 'daily_ticker_backup.json',
        ),
      ],
      subject: 'Daily Ticker backup',
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
  if (result.status == ShareResultStatus.unavailable) {
    throw BackupException('Sharing is not available on this device.');
  }
}

/// Picks a `.json` backup and returns parsed app data.
Future<AppData> importProgressBackup() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    throw BackupCancelled();
  }

  final picked = result.files.single;
  final String raw;
  if (picked.bytes != null) {
    raw = utf8.decode(picked.bytes!);
  } else if (picked.path != null) {
    raw = await File(picked.path!).readAsString();
  } else {
    throw BackupException('Could not read the selected file.');
  }

  final parsed = parseAppDataJson(raw);
  if (parsed == null) {
    throw BackupException(
      'Invalid backup file. Choose a Daily Ticker .json export.',
    );
  }
  return parsed;
}
