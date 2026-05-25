import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/defaults.dart';
import '../data/storage.dart';
import '../models/types.dart';
import '../utils/date_utils.dart';

class AppProvider extends ChangeNotifier {
  AppProvider();

  static const _uuid = Uuid();

  AppData _data = emptyAppData;
  bool ready = false;
  AppTab tab = AppTab.today;
  bool showProfilePicker = false;

  AppData get data => _data;

  Profile? get activeProfile {
    if (_data.activeProfileId == null) return null;
    try {
      return _data.profiles.firstWhere((p) => p.id == _data.activeProfileId);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    _data = await loadAppData();
    ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (ready) {
      await saveAppData(_data);
    }
  }

  void _update(AppData newData) {
    _data = newData;
    notifyListeners();
    _persist();
  }

  void setTab(AppTab newTab) {
    tab = newTab;
    notifyListeners();
  }

  void openProfilePicker() {
    showProfilePicker = true;
    notifyListeners();
  }

  void closeProfilePicker() {
    showProfilePicker = false;
    notifyListeners();
  }

  void createProfile(String name, String avatar) {
    final profileId = _uuid.v4();
    final profile = Profile(
      id: profileId,
      name: name.trim(),
      avatar: avatar,
      createdAt: DateTime.now().toIso8601String(),
    );

    final missions = defaultMissions.asMap().entries.map((entry) {
      final m = entry.value;
      return Mission(
        id: _uuid.v4(),
        profileId: profileId,
        name: m.name,
        icon: m.icon,
        color: m.color,
        sortOrder: entry.key,
        weeklyGoal: m.weeklyGoal,
      );
    }).toList();

    _update(_data.copyWith(
      profiles: [..._data.profiles, profile],
      activeProfileId: profileId,
      missions: [..._data.missions, ...missions],
    ));
    showProfilePicker = false;
    tab = AppTab.today;
    notifyListeners();
  }

  void switchProfile(String profileId) {
    _update(_data.copyWith(activeProfileId: profileId));
    showProfilePicker = false;
    notifyListeners();
  }

  List<Mission> getMissionsForProfile(String profileId) {
    return _data.missions
        .where((m) => m.profileId == profileId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  void addMission({
    required String name,
    required String icon,
    required String color,
    required int weeklyGoal,
  }) {
    final profileId = _data.activeProfileId;
    if (profileId == null) return;

    final profileMissions = getMissionsForProfile(profileId);
    final newMission = Mission(
      id: _uuid.v4(),
      profileId: profileId,
      name: name,
      icon: icon,
      color: color,
      sortOrder: profileMissions.length,
      weeklyGoal: weeklyGoal,
    );

    _update(_data.copyWith(missions: [..._data.missions, newMission]));
  }

  void updateMission(
    String id, {
    String? name,
    String? icon,
    String? color,
    int? weeklyGoal,
  }) {
    _update(_data.copyWith(
      missions: _data.missions.map((m) {
        if (m.id != id) return m;
        return m.copyWith(
          name: name,
          icon: icon,
          color: color,
          weeklyGoal: weeklyGoal,
        );
      }).toList(),
    ));
  }

  void deleteMission(String id) {
    _update(_data.copyWith(
      missions: _data.missions.where((m) => m.id != id).toList(),
    ));
  }

  void reorderMissions(List<String> orderedIds) {
    _update(_data.copyWith(
      missions: _data.missions.map((m) {
        final idx = orderedIds.indexOf(m.id);
        return idx >= 0 ? m.copyWith(sortOrder: idx) : m;
      }).toList(),
    ));
  }

  DailyEntry? getTodayEntry() {
    final profileId = _data.activeProfileId;
    if (profileId == null) return null;
    final date = todayKey();
    try {
      return _data.dailyEntries.firstWhere(
        (e) => e.profileId == profileId && e.date == date,
      );
    } catch (_) {
      return null;
    }
  }

  void setWeather(Weather weather) {
    final profileId = _data.activeProfileId;
    if (profileId == null) return;
    final date = todayKey();

    final existing = getTodayEntry();
    if (existing != null) {
      _update(_data.copyWith(
        dailyEntries: _data.dailyEntries.map((e) {
          if (e.profileId == profileId && e.date == date) {
            return e.copyWith(weather: weather);
          }
          return e;
        }).toList(),
      ));
    } else {
      _update(_data.copyWith(
        dailyEntries: [
          ..._data.dailyEntries,
          DailyEntry(profileId: profileId, date: date, weather: weather),
        ],
      ));
    }
  }

  void setMood(Mood mood) {
    final profileId = _data.activeProfileId;
    if (profileId == null) return;
    final date = todayKey();

    final existing = getTodayEntry();
    if (existing != null) {
      _update(_data.copyWith(
        dailyEntries: _data.dailyEntries.map((e) {
          if (e.profileId == profileId && e.date == date) {
            return e.copyWith(mood: mood);
          }
          return e;
        }).toList(),
      ));
    } else {
      _update(_data.copyWith(
        dailyEntries: [
          ..._data.dailyEntries,
          DailyEntry(profileId: profileId, date: date, mood: mood),
        ],
      ));
    }
  }

  List<String> getTodaySelectedMissions() {
    final profileId = _data.activeProfileId;
    if (profileId == null) return [];
    final date = todayKey();
    return _data.dailyMissions
        .where((dm) => dm.profileId == profileId && dm.date == date)
        .map((dm) => dm.missionId)
        .toList();
  }

  void toggleMissionOnToday(String missionId) {
    final profileId = _data.activeProfileId;
    if (profileId == null) return;
    final date = todayKey();

    final exists = _data.dailyMissions.any(
      (dm) =>
          dm.profileId == profileId &&
          dm.date == date &&
          dm.missionId == missionId,
    );

    if (exists) {
      _update(_data.copyWith(
        dailyMissions: _data.dailyMissions
            .where((dm) =>
                !(dm.profileId == profileId &&
                    dm.date == date &&
                    dm.missionId == missionId))
            .toList(),
      ));
    } else {
      _update(_data.copyWith(
        dailyMissions: [
          ..._data.dailyMissions,
          DailyMission(
            profileId: profileId,
            date: date,
            missionId: missionId,
            completed: false,
          ),
        ],
      ));
    }
  }

  void toggleMissionComplete(String missionId) {
    final profileId = _data.activeProfileId;
    if (profileId == null) return;
    final date = todayKey();

    _update(_data.copyWith(
      dailyMissions: _data.dailyMissions.map((dm) {
        if (dm.profileId == profileId &&
            dm.date == date &&
            dm.missionId == missionId) {
          final completed = !dm.completed;
          return dm.copyWith(
            completed: completed,
            completedAt: completed ? DateTime.now().toIso8601String() : null,
            clearCompletedAt: !completed,
          );
        }
        return dm;
      }).toList(),
    ));
  }

  void removeFromToday(String missionId) {
    final profileId = _data.activeProfileId;
    if (profileId == null) return;
    final date = todayKey();

    _update(_data.copyWith(
      dailyMissions: _data.dailyMissions
          .where((dm) =>
              !(dm.profileId == profileId &&
                  dm.date == date &&
                  dm.missionId == missionId))
          .toList(),
    ));
  }
}
