import '../models/types.dart';
import '../utils/date_utils.dart';

class MissionCount {
  const MissionCount({required this.mission, required this.count});
  final Mission mission;
  final int count;
}

List<DailyMission> getCompletedMissions(
  List<DailyMission> dailyMissions,
  String profileId,
  Period period, [
  DateTime? ref,
]) {
  final range = getPeriodRange(period, ref);
  return dailyMissions.where((dm) {
    return dm.profileId == profileId &&
        dm.completed &&
        isDateInRange(dm.date, range.start, range.end);
  }).toList();
}

int countStars(
  List<DailyMission> dailyMissions,
  String profileId,
  Period period, [
  DateTime? ref,
]) {
  return getCompletedMissions(dailyMissions, profileId, period, ref).length;
}

List<MissionCount> getTopMissions(
  List<DailyMission> dailyMissions,
  List<Mission> missions,
  String profileId,
  Period period, [
  DateTime? ref,
]) {
  final completed = getCompletedMissions(dailyMissions, profileId, period, ref);
  final counts = <String, int>{};

  for (final dm in completed) {
    counts[dm.missionId] = (counts[dm.missionId] ?? 0) + 1;
  }

  return missions
      .where((m) => m.profileId == profileId && counts.containsKey(m.id))
      .map((mission) => MissionCount(
            mission: mission,
            count: counts[mission.id] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
}

int getStreak(List<DailyMission> dailyMissions, String profileId) {
  final activeDays = <String>{};

  for (final dm in dailyMissions) {
    if (dm.profileId == profileId && dm.completed) {
      activeDays.add(dm.date);
    }
  }

  var streak = 0;
  var cursor = DateTime.now();
  cursor = DateTime(cursor.year, cursor.month, cursor.day);

  while (true) {
    final key = formatDateKey(cursor);
    if (activeDays.contains(key)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    } else if (key == todayKey()) {
      cursor = cursor.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return streak;
}

Set<int> getActiveDaysInMonth(
  List<DailyMission> dailyMissions,
  String profileId,
  int year,
  int month,
) {
  final days = <int>{};
  final prefix = '$year-${(month + 1).toString().padLeft(2, '0')}-';

  for (final dm in dailyMissions) {
    if (dm.profileId == profileId && dm.completed && dm.date.startsWith(prefix)) {
      days.add(parseDateKey(dm.date).day);
    }
  }

  return days;
}

DateTime getEarliestActivityMonth(
  List<DailyMission> dailyMissions,
  List<DailyEntry> dailyEntries,
  String profileId, [
  DateTime? fallback,
]) {
  String? earliest;

  for (final dm in dailyMissions) {
    if (dm.profileId == profileId && dm.completed) {
      if (earliest == null || dm.date.compareTo(earliest) < 0) {
        earliest = dm.date;
      }
    }
  }

  for (final entry in dailyEntries) {
    if (entry.profileId == profileId) {
      if (earliest == null || entry.date.compareTo(earliest) < 0) {
        earliest = entry.date;
      }
    }
  }

  return earliest != null
      ? startOfMonth(parseDateKey(earliest))
      : startOfMonth(fallback ?? DateTime.now());
}

List<Mission> getDayRecap(
  List<DailyMission> dailyMissions,
  List<Mission> missions,
  String profileId,
  String dateKey,
) {
  final dayMissions = dailyMissions.where((dm) {
    return dm.profileId == profileId && dm.date == dateKey && dm.completed;
  });

  return dayMissions
      .map((dm) {
        try {
          return missions.firstWhere((m) => m.id == dm.missionId);
        } catch (_) {
          return null;
        }
      })
      .whereType<Mission>()
      .toList();
}

int getMissionCountInPeriod(
  List<DailyMission> dailyMissions,
  String profileId,
  String missionId,
  Period period, [
  DateTime? ref,
]) {
  final range = getPeriodRange(period, ref);
  return dailyMissions.where((dm) {
    return dm.profileId == profileId &&
        dm.missionId == missionId &&
        dm.completed &&
        isDateInRange(dm.date, range.start, range.end);
  }).length;
}

int getMaxStarsInDay(List<DailyMission> dailyMissions, String profileId) {
  final byDay = <String, int>{};

  for (final dm in dailyMissions) {
    if (dm.profileId == profileId && dm.completed) {
      byDay[dm.date] = (byDay[dm.date] ?? 0) + 1;
    }
  }

  if (byDay.isEmpty) return 0;
  return byDay.values.reduce((a, b) => a > b ? a : b);
}

int getLongestStreakWithMinStars(
  List<DailyMission> dailyMissions,
  String profileId,
  int minStars,
) {
  final starsByDay = <String, int>{};

  for (final dm in dailyMissions) {
    if (dm.profileId == profileId && dm.completed) {
      starsByDay[dm.date] = (starsByDay[dm.date] ?? 0) + 1;
    }
  }

  final qualifyingDays = starsByDay.entries
      .where((e) => e.value >= minStars)
      .map((e) => e.key)
      .toList()
    ..sort();

  if (qualifyingDays.isEmpty) return 0;

  var longest = 1;
  var current = 1;

  for (var i = 1; i < qualifyingDays.length; i++) {
    final prev = parseDateKey(qualifyingDays[i - 1]);
    final curr = parseDateKey(qualifyingDays[i]);
    final diffDays = curr.difference(prev).inDays;

    if (diffDays == 1) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }

  return longest;
}

bool hasCompletedAllMissionsInPeriod(
  List<DailyMission> dailyMissions,
  List<Mission> missions,
  String profileId,
  Period period, [
  DateTime? ref,
]) {
  final profileMissions = missions.where((m) => m.profileId == profileId).toList();
  if (profileMissions.isEmpty) return false;

  final range = getPeriodRange(period, ref);
  final completedIds = <String>{};

  for (final dm in dailyMissions) {
    if (dm.profileId == profileId &&
        dm.completed &&
        isDateInRange(dm.date, range.start, range.end)) {
      completedIds.add(dm.missionId);
    }
  }

  return profileMissions.every((m) => completedIds.contains(m.id));
}

Mission? getTopMissionName(
  List<DailyMission> dailyMissions,
  List<Mission> missions,
  String profileId,
  Period period, [
  DateTime? ref,
]) {
  final top = getTopMissions(dailyMissions, missions, profileId, period, ref);
  return top.isEmpty ? null : top.first.mission;
}
