import '../data/defaults.dart';
import '../models/types.dart';
import '../utils/date_utils.dart';
import '../utils/stats.dart';

const starWeekGoal = 35;
const starMonthGoal = 100;
const starYearGoal = 1750;

const growthStreakMax = 365;

/// Consecutive days with at least one star (Streak Keeper).
const streakKeeperPath = [
  (days: 0, rank: 'Explorer', icon: '🌱'),
  (days: 7, rank: 'Adventurer', icon: '🌿'),
  (days: 14, rank: 'Trailblazer', icon: '🥾'),
  (days: 30, rank: 'Champion', icon: '🏅'),
  (days: 60, rank: 'Legend', icon: '🌟'),
  (days: 365, rank: 'Master', icon: '👑'),
];

/// Longest run of consecutive days with 4+ stars (Steady Star).
const steadyStarPath = [
  (days: 0, rank: 'Explorer', icon: '🌱'),
  (days: 5, rank: 'Adventurer', icon: '🌿'),
  (days: 10, rank: 'Trailblazer', icon: '🥾'),
  (days: 21, rank: 'Champion', icon: '🏅'),
  (days: 45, rank: 'Legend', icon: '🌟'),
  (days: 365, rank: 'Master', icon: '👑'),
];

AchievementTier tierFromThresholds(
  int value,
  ({int bronze, int silver, int gold}) thresholds,
) {
  if (value >= thresholds.gold) return AchievementTier.gold;
  if (value >= thresholds.silver) return AchievementTier.silver;
  if (value >= thresholds.bronze) return AchievementTier.bronze;
  return AchievementTier.locked;
}

String tierLabel(AchievementTier tier) {
  if (tier == AchievementTier.locked) return '';
  return tier.name[0].toUpperCase() + tier.name.substring(1);
}

String tierProgressionHint(({int bronze, int silver, int gold}) thresholds) {
  return 'Earn ${thresholds.bronze} to unlock bronze · ${thresholds.silver} for silver · ${thresholds.gold} for gold';
}

Achievement buildTieredAchievement({
  required String id,
  required String title,
  required String icon,
  required AchievementCategory category,
  required int progress,
  required ({int bronze, int silver, int gold}) thresholds,
  required String unit,
}) {
  final tier = tierFromThresholds(progress, thresholds);
  final max = thresholds.gold;

  return Achievement(
    id: id,
    title: tier == AchievementTier.locked ? title : '$title — ${tierLabel(tier)}',
    description: tier == AchievementTier.gold
        ? 'Max level! $progress/$max $unit'
        : '$progress/$max $unit\n${tierProgressionHint(thresholds)}',
    icon: icon,
    category: category,
    tier: tier,
    unlocked: tier != AchievementTier.locked,
    progress: progress,
    target: max,
  );
}

({int bronze, int silver, int gold}) goalTierThresholds(int goal) {
  return (
    bronze: (goal * 0.25).ceil().clamp(1, goal),
    silver: (goal * 0.5).ceil().clamp(1, goal),
    gold: goal,
  );
}

AchievementTier goalProgressTier(int progress, int goal) {
  final t = goalTierThresholds(goal);
  if (progress >= t.gold) return AchievementTier.gold;
  if (progress >= t.silver) return AchievementTier.silver;
  if (progress >= t.bronze) return AchievementTier.bronze;
  return AchievementTier.locked;
}

/// Highest weekly-goal tier for a mission in one calendar week (Mon–Sun).
AchievementTier weeklyGoalTierForCount(int weekCount, int goal) {
  if (weekCount > goal) return AchievementTier.diamond;
  return goalProgressTier(weekCount, goal);
}

/// One medal per mission per week (highest tier that week), summed across all weeks.
WeeklyGoalMedalCounts computeWeeklyGoalLifetimeMedals(
  List<DailyMission> dailyMissions,
  List<Mission> missions,
  String profileId,
) {
  final missionById = {for (final m in missions) m.id: m};
  final weekMissionCounts = <String, Map<String, int>>{};

  for (final dm in dailyMissions) {
    if (dm.profileId != profileId || !dm.completed) continue;
    final weekKey = formatDateKey(startOfWeek(parseDateKey(dm.date)));
    final byMission = weekMissionCounts.putIfAbsent(weekKey, () => {});
    byMission[dm.missionId] = (byMission[dm.missionId] ?? 0) + 1;
  }

  var bronze = 0;
  var silver = 0;
  var gold = 0;
  var diamond = 0;

  for (final byMission in weekMissionCounts.values) {
    for (final entry in byMission.entries) {
      final mission = missionById[entry.key];
      final goal =
          mission != null ? getWeeklyGoal(mission) : defaultWeeklyGoal;
      switch (weeklyGoalTierForCount(entry.value, goal)) {
        case AchievementTier.bronze:
          bronze++;
        case AchievementTier.silver:
          silver++;
        case AchievementTier.gold:
          gold++;
        case AchievementTier.diamond:
          diamond++;
        default:
          break;
      }
    }
  }

  return WeeklyGoalMedalCounts(
    bronze: bronze,
    silver: silver,
    gold: gold,
    diamond: diamond,
  );
}

Achievement buildStarGoalAchievement({
  required String id,
  required String baseTitle,
  required String icon,
  required int progress,
  required int goal,
  required String unit,
}) {
  final tier = goalProgressTier(progress, goal);
  final thresholds = goalTierThresholds(goal);

  final titles = {
    AchievementTier.locked: baseTitle,
    AchievementTier.bronze: '$baseTitle — Getting Started',
    AchievementTier.silver: '$baseTitle — Almost There',
    AchievementTier.gold: '$baseTitle — Goal Hit!',
  };

  return Achievement(
    id: id,
    title: titles[tier]!,
    description: tier == AchievementTier.gold
        ? '$progress/$goal $unit — goal reached!'
        : '$progress/$goal $unit\n${tierProgressionHint(thresholds)}',
    icon: icon,
    category: AchievementCategory.stars,
    tier: tier,
    unlocked: tier != AchievementTier.locked,
    progress: progress.clamp(0, goal),
    target: goal,
  );
}

String growthRankTitle(
  int progress,
  List<({int days, String rank, String icon})> path,
  String baseTitle,
) {
  var rank = path.first.rank;
  for (final milestone in path) {
    if (progress >= milestone.days) rank = milestone.rank;
  }
  return '$baseTitle — $rank';
}

String growthRankIcon(
  int progress,
  List<({int days, String rank, String icon})> path,
) {
  var icon = path.first.icon;
  for (final milestone in path) {
    if (progress >= milestone.days) icon = milestone.icon;
  }
  return icon;
}

Achievement buildGrowthStreakAchievement({
  required String id,
  required String baseTitle,
  required int progress,
  required List<({int days, String rank, String icon})> path,
  required String unit,
}) {
  final title = growthRankTitle(progress, path, baseTitle);
  final max = growthStreakMax;
  final capped = progress.clamp(0, max);
  final isMaster = capped >= max;

  return Achievement(
    id: id,
    title: title,
    description: isMaster
        ? '$capped/$max $unit — Master achieved!'
        : '$capped/$max $unit',
    icon: growthRankIcon(progress, path),
    category: AchievementCategory.streak,
    tier: AchievementTier.locked,
    unlocked: true,
    progress: capped,
    target: max,
    growthStyle: true,
  );
}

Achievement buildWeeklyGoalAchievement(Mission mission, int weekCount) {
  final goal = getWeeklyGoal(mission);
  final tier = weeklyGoalTierForCount(weekCount, goal);

  if (tier == AchievementTier.diamond) {
    return Achievement(
      id: 'subject-${mission.id}',
      title: '${mission.name} — Diamond',
      description:
          '$weekCount/$goal stars this week — hidden bonus! You beat your goal!',
      icon: mission.icon,
      category: AchievementCategory.subject,
      tier: AchievementTier.diamond,
      unlocked: true,
      progress: weekCount,
      target: goal,
      missionId: mission.id,
    );
  }
  final thresholds = goalTierThresholds(goal);

  final titles = {
    AchievementTier.locked: '${mission.name} Weekly Goal',
    AchievementTier.bronze: '${mission.name} — Getting Started',
    AchievementTier.silver: '${mission.name} — Almost There',
    AchievementTier.gold: '${mission.name} — Goal Hit!',
  };

  return Achievement(
    id: 'subject-${mission.id}',
    title: titles[tier]!,
    description: tier == AchievementTier.gold
        ? '$weekCount/$goal stars this week — goal reached!'
        : '$weekCount/$goal stars this week (Mon–Sun)\n${tierProgressionHint(thresholds)}',
    icon: mission.icon,
    category: AchievementCategory.subject,
    tier: tier,
    unlocked: tier != AchievementTier.locked,
    progress: weekCount.clamp(0, goal),
    target: goal,
    missionId: mission.id,
  );
}

List<Achievement> computeAchievements(
  List<DailyMission> dailyMissions,
  List<Mission> missions,
  String profileId,
) {
  final profileMissions =
      missions.where((m) => m.profileId == profileId).toList();

  final weekStars = countStars(dailyMissions, profileId, Period.week);
  final monthStars = countStars(dailyMissions, profileId, Period.month);
  final yearStars = countStars(dailyMissions, profileId, Period.year);
  final streak = getStreak(dailyMissions, profileId);
  final consistentStreak =
      getLongestStreakWithMinStars(dailyMissions, profileId, 4);
  final maxDayStars = getMaxStarsInDay(dailyMissions, profileId);
  final triedEverything = hasCompletedAllMissionsInPeriod(
    dailyMissions,
    missions,
    profileId,
    Period.month,
  );

  final starAchievements = [
    buildStarGoalAchievement(
      id: 'star-week',
      baseTitle: 'Weekly Star Hunter',
      icon: '⭐',
      progress: weekStars,
      goal: starWeekGoal,
      unit: 'stars this week',
    ),
    buildStarGoalAchievement(
      id: 'star-month',
      baseTitle: 'Monthly Star Master',
      icon: '🌟',
      progress: monthStars,
      goal: starMonthGoal,
      unit: 'stars this month',
    ),
    buildStarGoalAchievement(
      id: 'star-year',
      baseTitle: 'Year Legend',
      icon: '🎖️',
      progress: yearStars,
      goal: starYearGoal,
      unit: 'stars this year',
    ),
  ];

  final streakAchievements = [
    buildGrowthStreakAchievement(
      id: 'streak-active',
      baseTitle: 'Streak Keeper',
      progress: streak,
      path: streakKeeperPath,
      unit: 'day streak',
    ),
    buildGrowthStreakAchievement(
      id: 'streak-consistent',
      baseTitle: 'Steady Star',
      progress: consistentStreak,
      path: steadyStarPath,
      unit: 'days with 4+ stars in a row',
    ),
  ];

  final subjectAchievements = profileMissions
      .map((mission) => buildWeeklyGoalAchievement(
            mission,
            getMissionCountInPeriod(
              dailyMissions,
              profileId,
              mission.id,
              Period.week,
            ),
          ))
      .toList();

  final specialAchievements = [
    Achievement(
      id: 'special-power-day',
      title: maxDayStars >= 5 ? 'Power Day — Gold' : 'Power Day',
      description: maxDayStars >= 5
          ? 'Best day: $maxDayStars stars!'
          : '$maxDayStars/5 stars in one day',
      icon: '⚡',
      category: AchievementCategory.special,
      tier: maxDayStars >= 6
          ? AchievementTier.gold
          : maxDayStars >= 5
              ? AchievementTier.silver
              : AchievementTier.locked,
      unlocked: maxDayStars >= 5,
      progress: maxDayStars.clamp(0, 6),
      target: maxDayStars >= 6 ? 6 : 5,
    ),
    Achievement(
      id: 'special-super-day',
      title: maxDayStars >= 6 ? 'Super Day — Gold' : 'Super Day',
      description: maxDayStars >= 6
          ? 'You nailed 6 missions in one day!'
          : '$maxDayStars/6 stars in one day',
      icon: '🚀',
      category: AchievementCategory.special,
      tier: maxDayStars >= 6 ? AchievementTier.gold : AchievementTier.locked,
      unlocked: maxDayStars >= 6,
      progress: maxDayStars,
      target: 6,
    ),
    Achievement(
      id: 'special-mission-mix',
      title: triedEverything ? 'Mission Mix — Gold' : 'Mission Mix',
      description: triedEverything
          ? 'You tried every mission this month!'
          : 'Complete every mission once this month',
      icon: '🌈',
      category: AchievementCategory.special,
      tier: triedEverything ? AchievementTier.gold : AchievementTier.locked,
      unlocked: triedEverything,
      progress: triedEverything ? profileMissions.length : 0,
      target: profileMissions.isEmpty ? 1 : profileMissions.length,
    ),
  ];

  return [
    ...starAchievements,
    ...streakAchievements,
    ...subjectAchievements,
    ...specialAchievements,
  ];
}

Map<AchievementCategory, List<Achievement>> groupAchievementsByCategory(
  List<Achievement> achievements,
) {
  final groups = {
    AchievementCategory.stars: <Achievement>[],
    AchievementCategory.streak: <Achievement>[],
    AchievementCategory.subject: <Achievement>[],
    AchievementCategory.special: <Achievement>[],
  };

  for (final achievement in achievements) {
    groups[achievement.category]!.add(achievement);
  }

  return groups;
}

const achievementCategoryLabels = {
  AchievementCategory.stars: (title: 'Star Collecting', icon: '⭐'),
  AchievementCategory.streak: (title: 'Streaks & Consistency', icon: '🔥'),
  AchievementCategory.subject: (title: 'Weekly Goals', icon: '🎯'),
  AchievementCategory.special: (title: 'Special Challenges', icon: '🏆'),
};

const starCollectingDisplayOrder = ['star-week', 'star-month', 'star-year'];

const streakDisplayOrder = ['streak-active', 'streak-consistent'];

List<Achievement> sortAchievementsForDisplay(
  List<Achievement> achievements, {
  AchievementCategory? category,
}) {
  const tierOrder = {
    AchievementTier.diamond: -1,
    AchievementTier.gold: 0,
    AchievementTier.silver: 1,
    AchievementTier.bronze: 2,
    AchievementTier.locked: 3,
  };

  final sorted = List<Achievement>.from(achievements);
  sorted.sort((a, b) {
    if (category == AchievementCategory.stars) {
      final aIdx = starCollectingDisplayOrder.indexOf(a.id);
      final bIdx = starCollectingDisplayOrder.indexOf(b.id);
      if (aIdx != -1 && bIdx != -1) return aIdx.compareTo(bIdx);
    }
    if (category == AchievementCategory.streak) {
      final aIdx = streakDisplayOrder.indexOf(a.id);
      final bIdx = streakDisplayOrder.indexOf(b.id);
      if (aIdx != -1 && bIdx != -1) return aIdx.compareTo(bIdx);
    }

    if (a.growthStyle && b.growthStyle) {
      return b.progress.compareTo(a.progress);
    }

    final tierDiff = tierOrder[a.tier]! - tierOrder[b.tier]!;
    if (tierDiff != 0) return tierDiff;
    final aRatio = a.target > 0 ? a.progress / a.target : 0.0;
    final bRatio = b.target > 0 ? b.progress / b.target : 0.0;
    return bRatio.compareTo(aRatio);
  });
  return sorted;
}

String achievementCategorySubtitle(AchievementCategory category, String weekRange) {
  switch (category) {
    case AchievementCategory.stars:
      return 'Earn more stars each week, month, and year';
    case AchievementCategory.streak:
      return 'Build your streak — grow from Explorer to Master (up to 365 days)';
    case AchievementCategory.subject:
      return "Hit each mission's weekly goal (resets Monday · $weekRange) — beat your goal for a hidden 💎 Diamond!";
    case AchievementCategory.special:
      return 'Bonus badges for big days and variety';
  }
}
