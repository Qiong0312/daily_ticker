import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/defaults.dart';
import '../models/types.dart';

const storageKey = 'daily_ticker_data';

const emptyAppData = AppData(
  profiles: [],
  activeProfileId: null,
  missions: [],
  dailyEntries: [],
  dailyMissions: [],
);

Future<AppData> loadAppData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return emptyAppData;

    final parsed = AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    return parsed.copyWith(
      missions: parsed.missions.map(normalizeMission).toList(),
    );
  } catch (_) {
    return emptyAppData;
  }
}

Future<void> saveAppData(AppData data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(storageKey, jsonEncode(data.toJson()));
}

String encodeAppData(AppData data) {
  return const JsonEncoder.withIndent('  ').convert(data.toJson());
}

AppData? parseAppDataJson(String raw) {
  try {
    final parsed = AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return parsed.copyWith(
      missions: parsed.missions.map(normalizeMission).toList(),
    );
  } catch (_) {
    return null;
  }
}
