enum Weather { sunny, partlyCloudy, cloudy, rainy, thunderstorm }

enum Mood { happy, okay, tired, frustrated, excited }

enum AppTab { today, wins, missions }

enum Period { week, month, year }

enum AchievementCategory { stars, streak, subject, special }

enum AchievementTier { diamond, bronze, silver, gold, locked }

class WeeklyGoalMedalCounts {
  const WeeklyGoalMedalCounts({
    this.bronze = 0,
    this.silver = 0,
    this.gold = 0,
    this.diamond = 0,
  });

  final int bronze;
  final int silver;
  final int gold;
  final int diamond;
}

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String avatar;
  final String createdAt;

  Profile copyWith({
    String? id,
    String? name,
    String? avatar,
    String? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'createdAt': createdAt,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: json['name'] as String,
        avatar: json['avatar'] as String,
        createdAt: json['createdAt'] as String,
      );
}

class Mission {
  const Mission({
    required this.id,
    required this.profileId,
    required this.name,
    required this.icon,
    required this.color,
    required this.sortOrder,
    this.weeklyGoal,
  });

  final String id;
  final String profileId;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final int? weeklyGoal;

  Mission copyWith({
    String? id,
    String? profileId,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    int? weeklyGoal,
  }) {
    return Mission(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'name': name,
        'icon': icon,
        'color': color,
        'sortOrder': sortOrder,
        if (weeklyGoal != null) 'weeklyGoal': weeklyGoal,
      };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        color: json['color'] as String,
        sortOrder: json['sortOrder'] as int,
        weeklyGoal: json['weeklyGoal'] as int?,
      );
}

class DailyEntry {
  const DailyEntry({
    required this.profileId,
    required this.date,
    this.weather,
    this.mood,
  });

  final String profileId;
  final String date;
  final Weather? weather;
  final Mood? mood;

  DailyEntry copyWith({
    String? profileId,
    String? date,
    Weather? weather,
    Mood? mood,
  }) {
    return DailyEntry(
      profileId: profileId ?? this.profileId,
      date: date ?? this.date,
      weather: weather ?? this.weather,
      mood: mood ?? this.mood,
    );
  }

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'date': date,
        if (weather != null) 'weather': weatherToJson(weather!),
        if (mood != null) 'mood': moodToJson(mood!),
      };

  factory DailyEntry.fromJson(Map<String, dynamic> json) => DailyEntry(
        profileId: json['profileId'] as String,
        date: json['date'] as String,
        weather: json['weather'] != null
            ? weatherFromJson(json['weather'] as String)
            : null,
        mood: json['mood'] != null ? moodFromJson(json['mood'] as String) : null,
      );
}

class DailyMission {
  const DailyMission({
    required this.profileId,
    required this.date,
    required this.missionId,
    required this.completed,
    this.completedAt,
  });

  final String profileId;
  final String date;
  final String missionId;
  final bool completed;
  final String? completedAt;

  DailyMission copyWith({
    String? profileId,
    String? date,
    String? missionId,
    bool? completed,
    String? completedAt,
    bool clearCompletedAt = false,
  }) {
    return DailyMission(
      profileId: profileId ?? this.profileId,
      date: date ?? this.date,
      missionId: missionId ?? this.missionId,
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'date': date,
        'missionId': missionId,
        'completed': completed,
        if (completedAt != null) 'completedAt': completedAt,
      };

  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
        profileId: json['profileId'] as String,
        date: json['date'] as String,
        missionId: json['missionId'] as String,
        completed: json['completed'] as bool,
        completedAt: json['completedAt'] as String?,
      );
}

class AppData {
  const AppData({
    required this.profiles,
    required this.activeProfileId,
    required this.missions,
    required this.dailyEntries,
    required this.dailyMissions,
  });

  final List<Profile> profiles;
  final String? activeProfileId;
  final List<Mission> missions;
  final List<DailyEntry> dailyEntries;
  final List<DailyMission> dailyMissions;

  AppData copyWith({
    List<Profile>? profiles,
    String? activeProfileId,
    List<Mission>? missions,
    List<DailyEntry>? dailyEntries,
    List<DailyMission>? dailyMissions,
  }) {
    return AppData(
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      missions: missions ?? this.missions,
      dailyEntries: dailyEntries ?? this.dailyEntries,
      dailyMissions: dailyMissions ?? this.dailyMissions,
    );
  }

  Map<String, dynamic> toJson() => {
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'activeProfileId': activeProfileId,
        'missions': missions.map((m) => m.toJson()).toList(),
        'dailyEntries': dailyEntries.map((e) => e.toJson()).toList(),
        'dailyMissions': dailyMissions.map((m) => m.toJson()).toList(),
      };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
        profiles: (json['profiles'] as List<dynamic>? ?? [])
            .map((e) => Profile.fromJson(e as Map<String, dynamic>))
            .toList(),
        activeProfileId: json['activeProfileId'] as String?,
        missions: (json['missions'] as List<dynamic>? ?? [])
            .map((e) => Mission.fromJson(e as Map<String, dynamic>))
             .toList(),
        dailyEntries: (json['dailyEntries'] as List<dynamic>? ?? [])
            .map((e) => DailyEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyMissions: (json['dailyMissions'] as List<dynamic>? ?? [])
            .map((e) => DailyMission.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.tier,
    required this.unlocked,
    required this.progress,
    required this.target,
    this.missionId,
    this.growthStyle = false,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementTier tier;
  final bool unlocked;
  final int progress;
  final int target;
  final String? missionId;
  /// Rank-based streak cards (no bronze/silver/gold medals).
  final bool growthStyle;
}

class WeatherOption {
  const WeatherOption(this.value, this.icon, this.label);
  final Weather value;
  final String icon;
  final String label;
}

class MoodOption {
  const MoodOption(this.value, this.icon, this.label);
  final Mood value;
  final String icon;
  final String label;
}

const weatherOptions = [
  WeatherOption(Weather.sunny, '☀️', 'Sunny'),
  WeatherOption(Weather.partlyCloudy, '🌤️', 'Partly cloudy'),
  WeatherOption(Weather.cloudy, '☁️', 'Cloudy'),
  WeatherOption(Weather.rainy, '🌧️', 'Rainy'),
  WeatherOption(Weather.thunderstorm, '⛈️', 'Thunderstorm'),
];

const moodOptions = [
  MoodOption(Mood.happy, '😊', 'Happy'),
  MoodOption(Mood.okay, '😐', 'Okay'),
  MoodOption(Mood.tired, '😴', 'Tired'),
  MoodOption(Mood.frustrated, '😤', 'Frustrated'),
  MoodOption(Mood.excited, '🤩', 'Excited'),
];

const avatarOptions = [
  '🦁', '🐼', '🦊', '🐸', '🦄', '🐯', '🐨', '🐰', '🐶', '🐱',
];

const missionIcons = [
  '📖', '🀄', '🔢', '🔬', '🥋', '🎹', '⚽', '🎨', '🏃', '🎮',
  '📝', '🌍', '🎵', '🧪', '📚', '🏊', '🎯', '💻', '🧘', '⭐',
];

const missionColors = [
  '#4ECDC4', '#FF6B6B', '#A78BFA', '#51CF66', '#FFE66D',
  '#FF8FAB', '#74C0FC', '#FFA94D', '#69DB7C', '#DA77F2',
];

String weatherToJson(Weather w) {
  switch (w) {
    case Weather.sunny:
      return 'sunny';
    case Weather.partlyCloudy:
      return 'partly-cloudy';
    case Weather.cloudy:
      return 'cloudy';
    case Weather.rainy:
      return 'rainy';
    case Weather.thunderstorm:
      return 'thunderstorm';
  }
}

Weather weatherFromJson(String s) {
  switch (s) {
    case 'sunny':
      return Weather.sunny;
    case 'partly-cloudy':
      return Weather.partlyCloudy;
    case 'cloudy':
      return Weather.cloudy;
    case 'rainy':
      return Weather.rainy;
    case 'thunderstorm':
      return Weather.thunderstorm;
    default:
      return Weather.sunny;
  }
}

String moodToJson(Mood m) {
  switch (m) {
    case Mood.happy:
      return 'happy';
    case Mood.okay:
      return 'okay';
    case Mood.tired:
      return 'tired';
    case Mood.frustrated:
      return 'frustrated';
    case Mood.excited:
      return 'excited';
  }
}

Mood moodFromJson(String s) {
  switch (s) {
    case 'happy':
      return Mood.happy;
    case 'okay':
      return Mood.okay;
    case 'tired':
      return Mood.tired;
    case 'frustrated':
      return Mood.frustrated;
    case 'excited':
      return Mood.excited;
    default:
      return Mood.happy;
  }
}
