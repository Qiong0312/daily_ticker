import {
  countStars,
  getLongestStreakWithMinStars,
  getMaxStarsInDay,
  getMissionCountInPeriod,
  getStreak,
  hasCompletedAllMissionsInPeriod,
} from "./stats";
import { getWeeklyGoal } from "./mission-utils";
import type { Achievement, DailyMission, Mission } from "./types";

type Tier = Achievement["tier"];

const STAR_WEEK_GOAL = 35;
const STAR_MONTH_GOAL = 100;
const STAR_YEAR_GOAL = 1750;

const STREAK_DAYS = { bronze: 3, silver: 7, gold: 14 };
const CONSISTENT_DAYS = { bronze: 5, silver: 7, gold: 10 };

function tierFromThresholds(
  value: number,
  thresholds: { bronze: number; silver: number; gold: number }
): Tier {
  if (value >= thresholds.gold) return "gold";
  if (value >= thresholds.silver) return "silver";
  if (value >= thresholds.bronze) return "bronze";
  return "locked";
}

function tierLabel(tier: Tier): string {
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

function goalProgressTier(progress: number, goal: number): Tier {
  const { bronze, silver, gold } = goalTierThresholds(goal);
  if (progress >= gold) return "gold";
  if (progress >= silver) return "silver";
  if (progress >= bronze) return "bronze";
  return "locked";
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
  const tier = goalProgressTier(weekCount, goal);
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
    buildTieredAchievement(
      "streak-active",
      "Streak Keeper",
      "🔥",
      "streak",
      streak,
      STREAK_DAYS,
      "day streak"
    ),
    buildTieredAchievement(
      "streak-consistent",
      "Steady Star",
      "💪",
      "streak",
      consistentStreak,
      CONSISTENT_DAYS,
      "days with 4+ stars"
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

export function sortAchievementsForDisplay(
  achievements: Achievement[]
): Achievement[] {
  const tierOrder = { gold: 0, silver: 1, bronze: 2, locked: 3 };

  return [...achievements].sort((a, b) => {
    const tierDiff = tierOrder[a.tier] - tierOrder[b.tier];
    if (tierDiff !== 0) return tierDiff;
    const aRatio = a.target > 0 ? a.progress / a.target : 0;
    const bRatio = b.target > 0 ? b.progress / b.target : 0;
    return bRatio - aRatio;
  });
}
