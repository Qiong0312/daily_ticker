import {
  getPeriodRange,
  isDateInRange,
  parseDateKey,
  todayKey,
} from "./date-utils";
import type { DailyMission, Mission, Period } from "./types";

export interface MissionCount {
  mission: Mission;
  count: number;
}

export function getCompletedMissions(
  dailyMissions: DailyMission[],
  profileId: string,
  period: Period,
  ref: Date = new Date()
): DailyMission[] {
  const { start, end } = getPeriodRange(period, ref);
  return dailyMissions.filter(
    (dm) =>
      dm.profileId === profileId &&
      dm.completed &&
      isDateInRange(dm.date, start, end)
  );
}

export function countStars(
  dailyMissions: DailyMission[],
  profileId: string,
  period: Period,
  ref: Date = new Date()
): number {
  return getCompletedMissions(dailyMissions, profileId, period, ref).length;
}

export function getTopMissions(
  dailyMissions: DailyMission[],
  missions: Mission[],
  profileId: string,
  period: Period,
  ref: Date = new Date()
): MissionCount[] {
  const completed = getCompletedMissions(dailyMissions, profileId, period, ref);
  const counts = new Map<string, number>();

  for (const dm of completed) {
    counts.set(dm.missionId, (counts.get(dm.missionId) ?? 0) + 1);
  }

  return missions
    .filter((m) => m.profileId === profileId && counts.has(m.id))
    .map((mission) => ({
      mission,
      count: counts.get(mission.id) ?? 0,
    }))
    .sort((a, b) => b.count - a.count);
}

export function getStreak(
  dailyMissions: DailyMission[],
  profileId: string
): number {
  const activeDays = new Set<string>();

  for (const dm of dailyMissions) {
    if (dm.profileId === profileId && dm.completed) {
      activeDays.add(dm.date);
    }
  }

  let streak = 0;
  const cursor = new Date();
  cursor.setHours(0, 0, 0, 0);

  while (true) {
    const key = formatDateKey(cursor);
    if (activeDays.has(key)) {
      streak++;
      cursor.setDate(cursor.getDate() - 1);
    } else if (key === todayKey()) {
      cursor.setDate(cursor.getDate() - 1);
    } else {
      break;
    }
  }

  return streak;
}

function formatDateKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export function getActiveDaysInMonth(
  dailyMissions: DailyMission[],
  profileId: string,
  year: number,
  month: number
): Set<number> {
  const days = new Set<number>();
  const prefix = `${year}-${String(month + 1).padStart(2, "0")}-`;

  for (const dm of dailyMissions) {
    if (
      dm.profileId === profileId &&
      dm.completed &&
      dm.date.startsWith(prefix)
    ) {
      days.add(parseDateKey(dm.date).getDate());
    }
  }

  return days;
}

export function getDayRecap(
  dailyMissions: DailyMission[],
  missions: Mission[],
  profileId: string,
  dateKey: string
) {
  const dayMissions = dailyMissions.filter(
    (dm) => dm.profileId === profileId && dm.date === dateKey && dm.completed
  );
  return dayMissions
    .map((dm) => missions.find((m) => m.id === dm.missionId))
    .filter(Boolean) as Mission[];
}

export function getUniqueMissionsInPeriod(
  dailyMissions: DailyMission[],
  profileId: string,
  period: Period,
  ref: Date = new Date()
): number {
  const { start, end } = getPeriodRange(period, ref);
  const ids = new Set<string>();

  for (const dm of dailyMissions) {
    if (
      dm.profileId === profileId &&
      dm.completed &&
      isDateInRange(dm.date, start, end)
    ) {
      ids.add(dm.missionId);
    }
  }

  return ids.size;
}

export function getMissionCountInPeriod(
  dailyMissions: DailyMission[],
  profileId: string,
  missionId: string,
  period: Period,
  ref: Date = new Date()
): number {
  const { start, end } = getPeriodRange(period, ref);
  return dailyMissions.filter(
    (dm) =>
      dm.profileId === profileId &&
      dm.missionId === missionId &&
      dm.completed &&
      isDateInRange(dm.date, start, end)
  ).length;
}

export function getMissionCountAllTime(
  dailyMissions: DailyMission[],
  profileId: string,
  missionId: string
): number {
  return dailyMissions.filter(
    (dm) =>
      dm.profileId === profileId &&
      dm.missionId === missionId &&
      dm.completed
  ).length;
}

export function getMaxStarsInDay(
  dailyMissions: DailyMission[],
  profileId: string
): number {
  const byDay = new Map<string, number>();

  for (const dm of dailyMissions) {
    if (dm.profileId === profileId && dm.completed) {
      byDay.set(dm.date, (byDay.get(dm.date) ?? 0) + 1);
    }
  }

  if (byDay.size === 0) return 0;
  return Math.max(...byDay.values());
}

export function getLongestStreakWithMinStars(
  dailyMissions: DailyMission[],
  profileId: string,
  minStars: number
): number {
  const starsByDay = new Map<string, number>();

  for (const dm of dailyMissions) {
    if (dm.profileId === profileId && dm.completed) {
      starsByDay.set(dm.date, (starsByDay.get(dm.date) ?? 0) + 1);
    }
  }

  const qualifyingDays = [...starsByDay.entries()]
    .filter(([, count]) => count >= minStars)
    .map(([date]) => date)
    .sort();

  if (qualifyingDays.length === 0) return 0;

  let longest = 1;
  let current = 1;

  for (let i = 1; i < qualifyingDays.length; i++) {
    const prev = parseDateKey(qualifyingDays[i - 1]);
    const curr = parseDateKey(qualifyingDays[i]);
    const diffDays = Math.round(
      (curr.getTime() - prev.getTime()) / (1000 * 60 * 60 * 24)
    );

    if (diffDays === 1) {
      current++;
      longest = Math.max(longest, current);
    } else {
      current = 1;
    }
  }

  return longest;
}

export function hasCompletedAllMissionsInPeriod(
  dailyMissions: DailyMission[],
  missions: Mission[],
  profileId: string,
  period: Period,
  ref: Date = new Date()
): boolean {
  const profileMissions = missions.filter((m) => m.profileId === profileId);
  if (profileMissions.length === 0) return false;

  const { start, end } = getPeriodRange(period, ref);
  const completedIds = new Set<string>();

  for (const dm of dailyMissions) {
    if (
      dm.profileId === profileId &&
      dm.completed &&
      isDateInRange(dm.date, start, end)
    ) {
      completedIds.add(dm.missionId);
    }
  }

  return profileMissions.every((m) => completedIds.has(m.id));
}

export function getTopMissionName(
  dailyMissions: DailyMission[],
  missions: Mission[],
  profileId: string,
  period: Period,
  ref: Date = new Date()
): Mission | null {
  const top = getTopMissions(dailyMissions, missions, profileId, period, ref);
  return top[0]?.mission ?? null;
}
