import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/types.dart';
import 'widget_snapshot.dart';

const _channel = MethodChannel('com.dailyticker/widget_bridge');

/// Syncs today state with the iOS home screen widget via App Group storage.
class WidgetBridge {
  static bool get isSupported => !kIsWeb && Platform.isIOS;

  static Future<void> exportSnapshot(AppData data) async {
    if (!isSupported) return;
    final snapshot = WidgetSnapshot.fromAppData(data);
    try {
      await _channel.invokeMethod<void>(
        'writeSnapshot',
        jsonEncode(snapshot.toJson()),
      );
    } catch (e, st) {
      debugPrint('WidgetBridge.exportSnapshot failed: $e\n$st');
    }
  }

  /// If the widget edited data, merge into [data] and return updated app data.
  static Future<AppData> importIfNeeded(AppData data) async {
    if (!isSupported) return data;
    try {
      final raw = await _channel.invokeMethod<String>('readSnapshot');
      if (raw == null || raw.isEmpty) return data;

      final snapshot = WidgetSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (!snapshot.needsAppSync) return data;

      final merged = WidgetSnapshot.mergeIntoAppData(data, snapshot);
      await exportSnapshot(merged);
      return merged;
    } catch (e, st) {
      debugPrint('WidgetBridge.importIfNeeded failed: $e\n$st');
      return data;
    }
  }
}
