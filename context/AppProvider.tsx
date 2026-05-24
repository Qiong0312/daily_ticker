"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { DEFAULT_MISSIONS } from "@/lib/defaults";
import { todayKey } from "@/lib/date-utils";
import { EMPTY_APP_DATA, loadAppData, saveAppData } from "@/lib/storage";
import type {
  AppData,
  DailyEntry,
  Mission,
  Mood,
  Profile,
  Tab,
  Weather,
} from "@/lib/types";

function uid(): string {
  return crypto.randomUUID();
}

interface AppContextValue {
  ready: boolean;
  data: AppData;
  activeProfile: Profile | null;
  tab: Tab;
  setTab: (tab: Tab) => void;
  createProfile: (name: string, avatar: string) => void;
  switchProfile: (profileId: string) => void;
  showProfilePicker: boolean;
  openProfilePicker: () => void;
  closeProfilePicker: () => void;
  getMissionsForProfile: (profileId: string) => Mission[];
  addMission: (mission: Omit<Mission, "id" | "profileId" | "sortOrder">) => void;
  updateMission: (
    id: string,
    updates: Partial<Pick<Mission, "name" | "icon" | "color">>
  ) => void;
  deleteMission: (id: string) => void;
  reorderMissions: (orderedIds: string[]) => void;
  getTodayEntry: () => DailyEntry | undefined;
  setWeather: (weather: Weather) => void;
  setMood: (mood: Mood) => void;
  getTodaySelectedMissions: () => string[];
  toggleMissionOnToday: (missionId: string) => void;
  toggleMissionComplete: (missionId: string) => void;
  removeFromToday: (missionId: string) => void;
}

const AppContext = createContext<AppContextValue | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const [data, setData] = useState<AppData>(EMPTY_APP_DATA);
  const [ready, setReady] = useState(false);
  const [tab, setTab] = useState<Tab>("today");
  const [showProfilePicker, setShowProfilePicker] = useState(false);

  useEffect(() => {
    // Hydrate from localStorage after client mount (SSR has no window).
    const loaded = loadAppData();
    // eslint-disable-next-line react-hooks/set-state-in-effect -- intentional client hydration
    setData(loaded);
    setReady(true);
  }, []);

  useEffect(() => {
    if (ready) saveAppData(data);
  }, [data, ready]);

  const activeProfile = useMemo(
    () => data.profiles.find((p) => p.id === data.activeProfileId) ?? null,
    [data.profiles, data.activeProfileId]
  );

  const update = useCallback((fn: (prev: AppData) => AppData) => {
    setData((prev) => fn(prev));
  }, []);

  const createProfile = useCallback(
    (name: string, avatar: string) => {
      const profileId = uid();
      const profile: Profile = {
        id: profileId,
        name: name.trim(),
        avatar,
        createdAt: new Date().toISOString(),
      };
      const missions: Mission[] = DEFAULT_MISSIONS.map((m, i) => ({
        ...m,
        id: uid(),
        profileId,
        sortOrder: i,
      }));

      update((prev) => ({
        ...prev,
        profiles: [...prev.profiles, profile],
        activeProfileId: profileId,
        missions: [...prev.missions, ...missions],
      }));
      setShowProfilePicker(false);
      setTab("today");
    },
    [update]
  );

  const switchProfile = useCallback(
    (profileId: string) => {
      update((prev) => ({ ...prev, activeProfileId: profileId }));
      setShowProfilePicker(false);
    },
    [update]
  );

  const getMissionsForProfile = useCallback(
    (profileId: string) =>
      data.missions
        .filter((m) => m.profileId === profileId)
        .sort((a, b) => a.sortOrder - b.sortOrder),
    [data.missions]
  );

  const addMission = useCallback(
    (mission: Omit<Mission, "id" | "profileId" | "sortOrder">) => {
      if (!data.activeProfileId) return;
      const profileMissions = getMissionsForProfile(data.activeProfileId);
      const newMission: Mission = {
        ...mission,
        id: uid(),
        profileId: data.activeProfileId,
        sortOrder: profileMissions.length,
      };
      update((prev) => ({
        ...prev,
        missions: [...prev.missions, newMission],
      }));
    },
    [data.activeProfileId, getMissionsForProfile, update]
  );

  const updateMission = useCallback(
    (
      id: string,
      updates: Partial<Pick<Mission, "name" | "icon" | "color">>
    ) => {
      update((prev) => ({
        ...prev,
        missions: prev.missions.map((m) =>
          m.id === id ? { ...m, ...updates } : m
        ),
      }));
    },
    [update]
  );

  const deleteMission = useCallback(
    (id: string) => {
      update((prev) => ({
        ...prev,
        missions: prev.missions.filter((m) => m.id !== id),
      }));
    },
    [update]
  );

  const reorderMissions = useCallback(
    (orderedIds: string[]) => {
      update((prev) => ({
        ...prev,
        missions: prev.missions.map((m) => {
          const idx = orderedIds.indexOf(m.id);
          return idx >= 0 ? { ...m, sortOrder: idx } : m;
        }),
      }));
    },
    [update]
  );

  const getTodayEntry = useCallback(() => {
    if (!data.activeProfileId) return undefined;
    const date = todayKey();
    return data.dailyEntries.find(
      (e) => e.profileId === data.activeProfileId && e.date === date
    );
  }, [data.activeProfileId, data.dailyEntries]);

  const setWeather = useCallback(
    (weather: Weather) => {
      if (!data.activeProfileId) return;
      const date = todayKey();
      update((prev) => {
        const existing = prev.dailyEntries.find(
          (e) => e.profileId === data.activeProfileId && e.date === date
        );
        if (existing) {
          return {
            ...prev,
            dailyEntries: prev.dailyEntries.map((e) =>
              e.profileId === data.activeProfileId && e.date === date
                ? { ...e, weather }
                : e
            ),
          };
        }
        return {
          ...prev,
          dailyEntries: [
            ...prev.dailyEntries,
            { profileId: data.activeProfileId!, date, weather },
          ],
        };
      });
    },
    [data.activeProfileId, update]
  );

  const setMood = useCallback(
    (mood: Mood) => {
      if (!data.activeProfileId) return;
      const date = todayKey();
      update((prev) => {
        const existing = prev.dailyEntries.find(
          (e) => e.profileId === data.activeProfileId && e.date === date
        );
        if (existing) {
          return {
            ...prev,
            dailyEntries: prev.dailyEntries.map((e) =>
              e.profileId === data.activeProfileId && e.date === date
                ? { ...e, mood }
                : e
            ),
          };
        }
        return {
          ...prev,
          dailyEntries: [
            ...prev.dailyEntries,
            { profileId: data.activeProfileId!, date, mood },
          ],
        };
      });
    },
    [data.activeProfileId, update]
  );

  const getTodaySelectedMissions = useCallback(() => {
    if (!data.activeProfileId) return [];
    const date = todayKey();
    return data.dailyMissions
      .filter(
        (dm) => dm.profileId === data.activeProfileId && dm.date === date
      )
      .map((dm) => dm.missionId);
  }, [data.activeProfileId, data.dailyMissions]);

  const toggleMissionOnToday = useCallback(
    (missionId: string) => {
      if (!data.activeProfileId) return;
      const date = todayKey();
      const exists = data.dailyMissions.some(
        (dm) =>
          dm.profileId === data.activeProfileId &&
          dm.date === date &&
          dm.missionId === missionId
      );

      if (exists) {
        update((prev) => ({
          ...prev,
          dailyMissions: prev.dailyMissions.filter(
            (dm) =>
              !(
                dm.profileId === data.activeProfileId &&
                dm.date === date &&
                dm.missionId === missionId
              )
          ),
        }));
      } else {
        update((prev) => ({
          ...prev,
          dailyMissions: [
            ...prev.dailyMissions,
            {
              profileId: data.activeProfileId!,
              date,
              missionId,
              completed: false,
            },
          ],
        }));
      }
    },
    [data.activeProfileId, data.dailyMissions, update]
  );

  const toggleMissionComplete = useCallback(
    (missionId: string) => {
      if (!data.activeProfileId) return;
      const date = todayKey();
      update((prev) => ({
        ...prev,
        dailyMissions: prev.dailyMissions.map((dm) =>
          dm.profileId === data.activeProfileId &&
          dm.date === date &&
          dm.missionId === missionId
            ? {
                ...dm,
                completed: !dm.completed,
                completedAt: !dm.completed
                  ? new Date().toISOString()
                  : undefined,
              }
            : dm
        ),
      }));
    },
    [data.activeProfileId, update]
  );

  const removeFromToday = useCallback(
    (missionId: string) => {
      if (!data.activeProfileId) return;
      const date = todayKey();
      update((prev) => ({
        ...prev,
        dailyMissions: prev.dailyMissions.filter(
          (dm) =>
            !(
              dm.profileId === data.activeProfileId &&
              dm.date === date &&
              dm.missionId === missionId
            )
        ),
      }));
    },
    [data.activeProfileId, update]
  );

  const value: AppContextValue = {
    ready,
    data,
    activeProfile,
    tab,
    setTab,
    createProfile,
    switchProfile,
    showProfilePicker,
    openProfilePicker: () => setShowProfilePicker(true),
    closeProfilePicker: () => setShowProfilePicker(false),
    getMissionsForProfile,
    addMission,
    updateMission,
    deleteMission,
    reorderMissions,
    getTodayEntry,
    setWeather,
    setMood,
    getTodaySelectedMissions,
    toggleMissionOnToday,
    toggleMissionComplete,
    removeFromToday,
  };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useApp must be used within AppProvider");
  return ctx;
}
