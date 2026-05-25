import '../models/types.dart';
import '../utils/date_utils.dart';
import '../utils/stats.dart';

/// JSON shared with the iOS home screen widget (App Group file).
class WidgetSnapshot {
  const WidgetSnapshot({
    this.version = 1,
    required this.updatedAt,
    this.needsAppSync = false,
    this.activeProfileId,
    required this.dateKey,
    this.profile,
    this.streak = 0,
    this.entry,
    this.missions = const [],
    this.today = const [],
  });

  final int version;
  final String updatedAt;
  final bool needsAppSync;
  final String? activeProfileId;
  final String dateKey;
  final WidgetSnapshotProfile? profile;
  final int streak;
  final WidgetSnapshotEntry? entry;
  final List<WidgetSnapshotMission> missions;
  final List<WidgetSnapshotTodayItem> today;

  bool get allTodayComplete {
    if (today.isEmpty) return false;
    return today.every((t) => t.completed);
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'updatedAt': updatedAt,
        'needsAppSync': needsAppSync,
        'activeProfileId': activeProfileId,
        'dateKey': dateKey,
        if (profile != null) 'profile': profile!.toJson(),
        'streak': streak,
        if (entry != null) 'entry': entry!.toJson(),
        'missions': missions.map((m) => m.toJson()).toList(),
        'today': today.map((t) => t.toJson()).toList(),
      };

  factory WidgetSnapshot.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshot(
      version: json['version'] as int? ?? 1,
      updatedAt: json['updatedAt'] as String? ?? '',
      needsAppSync: json['needsAppSync'] as bool? ?? false,
      activeProfileId: json['activeProfileId'] as String?,
      dateKey: json['dateKey'] as String? ?? todayKey(),
      profile: json['profile'] != null
          ? WidgetSnapshotProfile.fromJson(
              json['profile'] as Map<String, dynamic>,
            )
          : null,
      streak: json['streak'] as int? ?? 0,
      entry: json['entry'] != null
          ? WidgetSnapshotEntry.fromJson(json['entry'] as Map<String, dynamic>)
          : null,
      missions: (json['missions'] as List<dynamic>? ?? [])
          .map(
            (e) => WidgetSnapshotMission.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      today: (json['today'] as List<dynamic>? ?? [])
          .map(
            (e) => WidgetSnapshotTodayItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  WidgetSnapshot copyWith({
    bool? needsAppSync,
    String? updatedAt,
  }) {
    return WidgetSnapshot(
      version: version,
      updatedAt: updatedAt ?? this.updatedAt,
      needsAppSync: needsAppSync ?? this.needsAppSync,
      activeProfileId: activeProfileId,
      dateKey: dateKey,
      profile: profile,
      streak: streak,
      entry: entry,
      missions: missions,
      today: today,
    );
  }

  static WidgetSnapshot fromAppData(AppData data) {
    final profileId = data.activeProfileId;
    final dateKey = todayKey();

    if (profileId == null) {
      return WidgetSnapshot(
        updatedAt: DateTime.now().toUtc().toIso8601String(),
        dateKey: dateKey,
      );
    }

    Profile? profile;
    for (final p in data.profiles) {
      if (p.id == profileId) {
        profile = p;
        break;
      }
    }

    final missions = data.missions
        .where((m) => m.profileId == profileId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final todayRows = data.dailyMissions
        .where((dm) => dm.profileId == profileId && dm.date == dateKey)
        .toList();

    final todayItems = <WidgetSnapshotTodayItem>[];
    for (final mission in missions) {
      DailyMission? dm;
      for (final row in todayRows) {
        if (row.missionId == mission.id) {
          dm = row;
          break;
        }
      }
      if (dm != null) {
        todayItems.add(
          WidgetSnapshotTodayItem(
            missionId: dm.missionId,
            completed: dm.completed,
          ),
        );
      }
    }

    DailyEntry? entry;
    for (final e in data.dailyEntries) {
      if (e.profileId == profileId && e.date == dateKey) {
        entry = e;
        break;
      }
    }

    return WidgetSnapshot(
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      needsAppSync: false,
      activeProfileId: profileId,
      dateKey: dateKey,
      profile: profile != null
          ? WidgetSnapshotProfile(
              id: profile.id,
              name: profile.name,
              avatar: profile.avatar,
            )
          : null,
      streak: getStreak(data.dailyMissions, profileId),
      entry: entry != null
          ? WidgetSnapshotEntry(
              weather: entry.weather != null ? weatherToJson(entry.weather!) : null,
              mood: entry.mood != null ? moodToJson(entry.mood!) : null,
            )
          : null,
      missions: missions
          .map(
            (m) => WidgetSnapshotMission(
              id: m.id,
              name: m.name,
              icon: m.icon,
              color: m.color,
              sortOrder: m.sortOrder,
            ),
          )
          .toList(),
      today: todayItems,
    );
  }

  /// Merge widget edits into full [AppData] (active profile + today only).
  static AppData mergeIntoAppData(AppData data, WidgetSnapshot snapshot) {
    final profileId = snapshot.activeProfileId ?? data.activeProfileId;
    if (profileId == null) return data;

    final dateKey = snapshot.dateKey;
    var dailyMissions = data.dailyMissions
        .where((dm) => !(dm.profileId == profileId && dm.date == dateKey))
        .toList();

    for (final item in snapshot.today) {
      dailyMissions.add(
        DailyMission(
          profileId: profileId,
          date: dateKey,
          missionId: item.missionId,
          completed: item.completed,
          completedAt: item.completed ? DateTime.now().toIso8601String() : null,
        ),
      );
    }

    var dailyEntries = List<DailyEntry>.from(data.dailyEntries);
    final entryIndex = dailyEntries.indexWhere(
      (e) => e.profileId == profileId && e.date == dateKey,
    );

    if (snapshot.entry != null &&
        (snapshot.entry!.weather != null || snapshot.entry!.mood != null)) {
      final weather = snapshot.entry!.weather != null
          ? weatherFromJson(snapshot.entry!.weather!)
          : null;
      final mood =
          snapshot.entry!.mood != null ? moodFromJson(snapshot.entry!.mood!) : null;

      if (entryIndex >= 0) {
        final existing = dailyEntries[entryIndex];
        dailyEntries[entryIndex] = existing.copyWith(
          weather: weather ?? existing.weather,
          mood: mood ?? existing.mood,
        );
      } else {
        dailyEntries.add(
          DailyEntry(
            profileId: profileId,
            date: dateKey,
            weather: weather,
            mood: mood,
          ),
        );
      }
    }

    return data.copyWith(
      dailyMissions: dailyMissions,
      dailyEntries: dailyEntries,
    );
  }
}

class WidgetSnapshotProfile {
  const WidgetSnapshotProfile({
    required this.id,
    required this.name,
    required this.avatar,
  });

  final String id;
  final String name;
  final String avatar;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
      };

  factory WidgetSnapshotProfile.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshotProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
    );
  }
}

class WidgetSnapshotEntry {
  const WidgetSnapshotEntry({this.weather, this.mood});

  final String? weather;
  final String? mood;

  Map<String, dynamic> toJson() => {
        if (weather != null) 'weather': weather,
        if (mood != null) 'mood': mood,
      };

  factory WidgetSnapshotEntry.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshotEntry(
      weather: json['weather'] as String?,
      mood: json['mood'] as String?,
    );
  }
}

class WidgetSnapshotMission {
  const WidgetSnapshotMission({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'sortOrder': sortOrder,
      };

  factory WidgetSnapshotMission.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshotMission(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class WidgetSnapshotTodayItem {
  const WidgetSnapshotTodayItem({
    required this.missionId,
    required this.completed,
  });

  final String missionId;
  final bool completed;

  Map<String, dynamic> toJson() => {
        'missionId': missionId,
        'completed': completed,
      };

  factory WidgetSnapshotTodayItem.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshotTodayItem(
      missionId: json['missionId'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
