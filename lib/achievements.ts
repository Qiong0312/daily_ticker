import {
  countStars,
  getLongestStreakWithMinStars,
  getMaxStarsInDay,
  getMissionCountInPeriod,
  getStreak,
  hasCompletedAllMissionsInPeriod,
} from "./stats";
import { DEFAULT_WEEKLY_GOAL, getWeeklyGoal } from "./mission-utils";
import { formatDateKey, parseDateKey, startOfWeek } from "./date-utils";
import type {
  Achievement,
  DailyMission,
  Mission,
  WeeklyGoalMedalCounts,
} from "./types";

/** Medal tiers from thresholds; diamond is only for weekly goals that exceed the target. */
type MedalTier = Exclude<Achievement["tier"], "diamond">;

const STAR_WEEK_GOAL = 35;
const STAR_MONTH_GOAL = 100;
const STAR_YEAR_GOAL = 1750;

const GROWTH_STREAK_MAX = 365;

const STREAK_KEEPER_PATH = [
  { days: 0, rank: "Explorer", icon: "🌱" },
  { days: 7, rank: "Adventurer", icon: "🌿" },
  { days: 14, rank: "Trailblazer", icon: "🥾" },
  { days: 30, rank: "Champion", icon: "🏅" },
  { days: 60, rank: "Legend", icon: "🌟" },
  { days: 365, rank: "Master", icon: "👑" },
] as const;

const STEADY_STAR_PATH = [
  { days: 0, rank: "Explorer", icon: "🌱" },
  { days: 5, rank: "Adventurer", icon: "🌿" },
  { days: 10, rank: "Trailblazer", icon: "🥾" },
  { days: 21, rank: "Champion", icon: "🏅" },
  { days: 45, rank: "Legend", icon: "🌟" },
  { days: 365, rank: "Master", icon: "👑" },
] as const;

type GrowthMilestone = { days: number; rank: string; icon: string };

function tierFromThresholds(
  value: number,
  thresholds: { bronze: number; silver: number; gold: number }
): MedalTier {
  if (value >= thresholds.gold) return "gold";
  if (value >= thresholds.silver) return "silver";
  if (value >= thresholds.bronze) return "bronze";
  return "locked";
}

function tierLabel(tier: MedalTier): string {
  if (tier === "locked") return "";
  return tier.charAt(0).toUpperCase() + tier.slice(1);
}

function tierProgressionHint(thresholds: {
  bronze: number;
  silver: number;
  gold: number;
}): string {
  return `Earn ${thresholds.bronze} to unlock bronze · ${thresholds.silver} for silver · ${thresholds.gold} for gold`;
}

function buildTieredAchievement(
  id: string,
  title: string,
  icon: string,
  category: Achievement["category"],
  progress: number,
  thresholds: { bronze: number; silver: number; gold: number },
  unit: string
): Achievement {
  const tier = tierFromThresholds(progress, thresholds);
  const max = thresholds.gold;

  return {
    id,
    title: tier === "locked" ? title : `${title} — ${tierLabel(tier)}`,
    description:
      tier === "gold"
        ? `Max level! ${progress}/${max} ${unit}`
        : `${progress}/${max} ${unit}\n${tierProgressionHint(thresholds)}`,
    icon,
    category,
    tier,
    unlocked: tier !== "locked",
    progress,
    target: max,
  };
}

function goalTierThresholds(goal: number): {
  bronze: number;
  silver: number;
  gold: number;
} {
  return {
    bronze: Math.max(1, Math.ceil(goal * 0.25)),
    silver: Math.max(1, Math.ceil(goal * 0.5)),
    gold: goal,
  };
}

function goalProgressTier(progress: number, goal: number): MedalTier {
  const { bronze, silver, gold } = goalTierThresholds(goal);
  if (progress >= gold) return "gold";
  if (progress >= silver) return "silver";
  if (progress >= bronze) return "bronze";
  return "locked";
}

/** Highest weekly-goal tier for a mission in one calendar week (Mon–Sun). */
export function weeklyGoalTierForCount(
  weekCount: number,
  goal: number
): Achievement["tier"] {
  if (weekCount > goal) return "diamond";
  return goalProgressTier(weekCount, goal);
}

/** One medal per mission per week (highest tier that week), summed across all weeks. */
export function computeWeeklyGoalLifetimeMedals(
  dailyMissions: DailyMission[],
  missions: Mission[],
  profileId: string
): WeeklyGoalMedalCounts {
  const counts: WeeklyGoalMedalCounts = {
    bronze: 0,
    silver: 0,
    gold: 0,
    diamond: 0,
  };
  const missionById = new Map(missions.map((m) => [m.id, m]));
  const weekMissionCounts = new Map<string, Map<string, number>>();

  for (const dm of dailyMissions) {
    if (dm.profileId !== profileId || !dm.completed) continue;
    const weekKey = formatDateKey(startOfWeek(parseDateKey(dm.date)));
    let byMission = weekMissionCounts.get(weekKey);
    if (!byMission) {
      byMission = new Map();
      weekMissionCounts.set(weekKey, byMission);
    }
    byMission.set(dm.missionId, (byMission.get(dm.missionId) ?? 0) + 1);
  }

  for (const byMission of weekMissionCounts.values()) {
    for (const [missionId, weekCount] of byMission) {
      const mission = missionById.get(missionId);
      const goal = mission ? getWeeklyGoal(mission) : DEFAULT_WEEKLY_GOAL;
      const tier = weeklyGoalTierForCount(weekCount, goal);
      if (tier === "locked") continue;
      counts[tier]++;
    }
  }

  return counts;
}

function growthRankTitle(
  progress: number,
  path: readonly GrowthMilestone[],
  baseTitle: string
): string {
  let rank = path[0].rank;
  for (const milestone of path) {
    if (progress >= milestone.days) rank = milestone.rank;
  }
  return `${baseTitle} — ${rank}`;
}

function growthRankIcon(
  progress: number,
  path: readonly GrowthMilestone[]
): string {
  let icon = path[0].icon;
  for (const milestone of path) {
    if (progress >= milestone.days) icon = milestone.icon;
  }
  return icon;
}

function buildGrowthStreakAchievement(
  id: string,
  baseTitle: string,
  progress: number,
  path: readonly GrowthMilestone[],
  unit: string
): Achievement {
  const title = growthRankTitle(progress, path, baseTitle);
  const max = GROWTH_STREAK_MAX;
  const capped = Math.min(progress, max);
  const isMaster = capped >= max;

  return {
    id,
    title,
    description: isMaster
      ? `${capped}/${max} ${unit} — Master achieved!`
      : `${capped}/${max} ${unit}`,
    icon: growthRankIcon(progress, path),
    category: "streak",
    tier: "locked",
    unlocked: true,
    progress: capped,
    target: max,
    growthStyle: true,
  };
}

function buildStarGoalAchievement(
  id: string,
  baseTitle: string,
  icon: string,
  progress: number,
  goal: number,
  unit: string
): Achievement {
  const tier = goalProgressTier(progress, goal);
  const thresholds = goalTierThresholds(goal);

  const titles = {
    locked: baseTitle,
    bronze: `${baseTitle} — Getting Started`,
    silver: `${baseTitle} — Almost There`,
    gold: `${baseTitle} — Goal Hit!`,
  };

  return {
    id,
    title: titles[tier],
    description:
      tier === "gold"
        ? `${progress}/${goal} ${unit} — goal reached!`
        : `${progress}/${goal} ${unit}\n${tierProgressionHint(thresholds)}`,
    icon,
    category: "stars",
    tier,
    unlocked: tier !== "locked",
    progress: Math.min(progress, goal),
    target: goal,
  };
}

function buildWeeklyGoalAchievement(
  mission: Mission,
  weekCount: number
): Achievement {
  const goal = getWeeklyGoal(mission);
  const tier = weeklyGoalTierForCount(weekCount, goal);

  if (tier === "diamond") {
    return {
      id: `subject-${mission.id}`,
      title: `${mission.name} — Diamond`,
      description: `${weekCount}/${goal} stars this week — hidden bonus! You beat your goal!`,
      icon: mission.icon,
      category: "subject",
      tier: "diamond",
      unlocked: true,
      progress: weekCount,
      target: goal,
      missionId: mission.id,
    };
  }
  const thresholds = goalTierThresholds(goal);

  const titles = {
    locked: `${mission.name} Weekly Goal`,
    bronze: `${mission.name} — Getting Started`,
    silver: `${mission.name} — Almost There`,
    gold: `${mission.name} — Goal Hit!`,
  };

  return {
    id: `subject-${mission.id}`,
    title: titles[tier],
    description:
      tier === "gold"
        ? `${weekCount}/${goal} stars this week — goal reached!`
        : `${weekCount}/${goal} stars this week (Mon–Sun)\n${tierProgressionHint(thresholds)}`,
    icon: mission.icon,
    category: "subject",
    tier,
    unlocked: tier !== "locked",
    progress: Math.min(weekCount, goal),
    target: goal,
    missionId: mission.id,
  };
}

export function computeAchievements(
  dailyMissions: DailyMission[],
  missions: Mission[],
  profileId: string
): Achievement[] {
  const profileMissions = missions.filter((m) => m.profileId === profileId);

  const weekStars = countStars(dailyMissions, profileId, "week");
  const monthStars = countStars(dailyMissions, profileId, "month");
  const yearStars = countStars(dailyMissions, profileId, "year");
  const streak = getStreak(dailyMissions, profileId);
  const consistentStreak = getLongestStreakWithMinStars(
    dailyMissions,
    profileId,
    4
  );
  const maxDayStars = getMaxStarsInDay(dailyMissions, profileId);
  const triedEverything = hasCompletedAllMissionsInPeriod(
    dailyMissions,
    missions,
    profileId,
    "month"
  );

  const starAchievements: Achievement[] = [
    buildStarGoalAchievement(
      "star-week",
      "Weekly Star Hunter",
      "⭐",
      weekStars,
      STAR_WEEK_GOAL,
      "stars this week"
    ),
    buildStarGoalAchievement(
      "star-month",
      "Monthly Star Master",
      "🌟",
      monthStars,
      STAR_MONTH_GOAL,
      "stars this month"
    ),
    buildStarGoalAchievement(
      "star-year",
      "Year Legend",
      "🎖️",
      yearStars,
      STAR_YEAR_GOAL,
      "stars this year"
    ),
  ];

  const streakAchievements: Achievement[] = [
    buildGrowthStreakAchievement(
      "streak-active",
      "Streak Keeper",
      streak,
      STREAK_KEEPER_PATH,
      "day streak"
    ),
    buildGrowthStreakAchievement(
      "streak-consistent",
      "Steady Star",
      consistentStreak,
      STEADY_STAR_PATH,
      "days with 4+ stars in a row"
    ),
  ];

  const subjectAchievements = profileMissions.map((mission) =>
    buildWeeklyGoalAchievement(
      mission,
      getMissionCountInPeriod(
        dailyMissions,
        profileId,
        mission.id,
        "week"
      )
    )
  );

  const specialAchievements: Achievement[] = [
    {
      id: "special-power-day",
      title: maxDayStars >= 5 ? "Power Day — Gold" : "Power Day",
      description:
        maxDayStars >= 5
          ? `Best day: ${maxDayStars} stars!`
          : `${maxDayStars}/5 stars in one day`,
      icon: "⚡",
      category: "special",
      tier: maxDayStars >= 6 ? "gold" : maxDayStars >= 5 ? "silver" : "locked",
      unlocked: maxDayStars >= 5,
      progress: Math.min(maxDayStars, 6),
      target: maxDayStars >= 6 ? 6 : 5,
    },
    {
      id: "special-super-day",
      title: maxDayStars >= 6 ? "Super Day — Gold" : "Super Day",
      description:
        maxDayStars >= 6
          ? "You nailed 6 missions in one day!"
          : `${maxDayStars}/6 stars in one day`,
      icon: "🚀",
      category: "special",
      tier: maxDayStars >= 6 ? "gold" : "locked",
      unlocked: maxDayStars >= 6,
      progress: maxDayStars,
      target: 6,
    },
    {
      id: "special-mission-mix",
      title: triedEverything ? "Mission Mix — Gold" : "Mission Mix",
      description: triedEverything
        ? "You tried every mission this month!"
        : "Complete every mission once this month",
      icon: "🌈",
      category: "special",
      tier: triedEverything ? "gold" : "locked",
      unlocked: triedEverything,
      progress: triedEverything ? profileMissions.length : 0,
      target: profileMissions.length || 1,
    },
  ];

  return [
    ...starAchievements,
    ...streakAchievements,
    ...subjectAchievements,
    ...specialAchievements,
  ];
}

export function groupAchievementsByCategory(achievements: Achievement[]) {
  const groups: Record<Achievement["category"], Achievement[]> = {
    stars: [],
    streak: [],
    subject: [],
    special: [],
  };

  for (const achievement of achievements) {
    groups[achievement.category].push(achievement);
  }

  return groups;
}

export const ACHIEVEMENT_CATEGORY_LABELS: Record<
  Achievement["category"],
  { title: string; icon: string }
> = {
  stars: { title: "Star Collecting", icon: "⭐" },
  streak: { title: "Streaks & Consistency", icon: "🔥" },
  subject: { title: "Weekly Goals", icon: "🎯" },
  special: { title: "Special Challenges", icon: "🏆" },
};

const STAR_COLLECTING_DISPLAY_ORDER = [
  "star-week",
  "star-month",
  "star-year",
] as const;

const STREAK_DISPLAY_ORDER = ["streak-active", "streak-consistent"] as const;

export function sortAchievementsForDisplay(
  achievements: Achievement[],
  category?: Achievement["category"]
): Achievement[] {
  const tierOrder = { diamond: -1, gold: 0, silver: 1, bronze: 2, locked: 3 };

  return [...achievements].sort((a, b) => {
    if (category === "stars") {
      const aIdx = STAR_COLLECTING_DISPLAY_ORDER.indexOf(
        a.id as (typeof STAR_COLLECTING_DISPLAY_ORDER)[number]
      );
      const bIdx = STAR_COLLECTING_DISPLAY_ORDER.indexOf(
        b.id as (typeof STAR_COLLECTING_DISPLAY_ORDER)[number]
      );
      if (aIdx !== -1 && bIdx !== -1) return aIdx - bIdx;
    }
    if (category === "streak") {
      const aIdx = STREAK_DISPLAY_ORDER.indexOf(
        a.id as (typeof STREAK_DISPLAY_ORDER)[number]
      );
      const bIdx = STREAK_DISPLAY_ORDER.indexOf(
        b.id as (typeof STREAK_DISPLAY_ORDER)[number]
      );
      if (aIdx !== -1 && bIdx !== -1) return aIdx - bIdx;
    }

    const tierDiff = tierOrder[a.tier] - tierOrder[b.tier];
    if (tierDiff !== 0) return tierDiff;
    const aRatio = a.target > 0 ? a.progress / a.target : 0;
    const bRatio = b.target > 0 ? b.progress / b.target : 0;
    return bRatio - aRatio;
  });
}
