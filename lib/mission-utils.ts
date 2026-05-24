import type { Mission } from "./types";

export const DEFAULT_WEEKLY_GOAL = 5;
export const MIN_WEEKLY_GOAL = 1;
export const MAX_WEEKLY_GOAL = 7;

export function getWeeklyGoal(mission: Mission): number {
  const goal = mission.weeklyGoal ?? DEFAULT_WEEKLY_GOAL;
  return Math.min(MAX_WEEKLY_GOAL, Math.max(MIN_WEEKLY_GOAL, goal));
}

export function normalizeMission(mission: Mission): Mission {
  return {
    ...mission,
    weeklyGoal: getWeeklyGoal(mission),
  };
}
