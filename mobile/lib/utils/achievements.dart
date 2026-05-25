import '../data/defaults.dart';
import '../models/types.dart';
import '../utils/stats.dart';

const starWeekGoal = 35;
const starMonthGoal = 100;
const starYearGoal = 1750;

const streakDays = (bronze: 3, silver: 7, gold: 14);
const consistentDays = (bronze: 5, silver: 7, gold: 10);

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

Achievement buildWeeklyGoalAchievement(Mission mission, int weekCount) {
  final goal = getWeeklyGoal(mission);
  final tier = goalProgressTier(weekCount, goal);
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
    buildTieredAchievement(
      id: 'streak-active',
      title: 'Streak Keeper',
      icon: '🔥',
      category: AchievementCategory.streak,
      progress: streak,
      thresholds: streakDays,
      unit: 'day streak',
    ),
    buildTieredAchievement(
      id: 'streak-consistent',
      title: 'Steady Star',
      icon: '💪',
      category: AchievementCategory.streak,
      progress: consistentStreak,
      thresholds: consistentDays,
      unit: 'days with 4+ stars',
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

List<Achievement> sortAchievementsForDisplay(List<Achievement> achievements) {
  const tierOrder = {
    AchievementTier.gold: 0,
    AchievementTier.silver: 1,
    AchievementTier.bronze: 2,
    AchievementTier.locked: 3,
  };

  final sorted = List<Achievement>.from(achievements);
  sorted.sort((a, b) {
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
      return 'Keep showing up — streaks take real dedication';
    case AchievementCategory.subject:
      return "Hit each mission's weekly goal (resets every Monday · $weekRange)";
    case AchievementCategory.special:
      return 'Bonus badges for big days and variety';
  }
}
