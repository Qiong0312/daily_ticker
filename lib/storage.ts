import type { AppData } from "./types";
import { normalizeMission } from "./mission-utils";

const STORAGE_KEY = "daily_ticker_data";

export const EMPTY_APP_DATA: AppData = {
  profiles: [],
  activeProfileId: null,
  missions: [],
  dailyEntries: [],
  dailyMissions: [],
};

export function loadAppData(): AppData {
  if (typeof window === "undefined") return EMPTY_APP_DATA;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return EMPTY_APP_DATA;
    const parsed = { ...EMPTY_APP_DATA, ...JSON.parse(raw) } as AppData;
    return {
      ...parsed,
      missions: parsed.missions.map(normalizeMission),
    };
  } catch {
    return EMPTY_APP_DATA;
  }
}

export function saveAppData(data: AppData): void {
  if (typeof window === "undefined") return;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
}
