"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useApp } from "@/context/AppProvider";
import { formatDisplayDate, todayKey } from "@/lib/date-utils";
import { getStreak } from "@/lib/stats";
import { MOOD_OPTIONS, WEATHER_OPTIONS } from "@/lib/types";

export function TodayView() {
  const {
    activeProfile,
    data,
    getMissionsForProfile,
    getTodayEntry,
    setWeather,
    setMood,
    getTodaySelectedMissions,
    toggleMissionOnToday,
    toggleMissionComplete,
    removeFromToday,
    setTab,
  } = useApp();

  const [justCompletedAll, setJustCompletedAll] = useState(false);
  const wasAllDone = useRef(false);

  const profileId = activeProfile?.id;
  const missions = profileId ? getMissionsForProfile(profileId) : [];

  const todayMissions = useMemo(() => {
    if (!profileId) return [];
    const dateKey = todayKey();
    return data.dailyMissions
      .filter((dm) => dm.profileId === profileId && dm.date === dateKey)
      .map((dm) => ({
        ...dm,
        mission: missions.find((m) => m.id === dm.missionId)!,
      }))
      .filter((dm) => dm.mission);
  }, [data.dailyMissions, profileId, missions]);

  const completedCount = todayMissions.filter((dm) => dm.completed).length;
  const totalCount = todayMissions.length;
  const allDone = totalCount > 0 && completedCount === totalCount;

  useEffect(() => {
    if (allDone && !wasAllDone.current) {
      setJustCompletedAll(true);
      const timer = setTimeout(() => setJustCompletedAll(false), 2500);
      wasAllDone.current = true;
      return () => clearTimeout(timer);
    }
    if (!allDone) {
      wasAllDone.current = false;
    }
  }, [allDone]);

  if (!activeProfile) return null;

  const entry = getTodayEntry();
  const selectedIds = getTodaySelectedMissions();
  const date = new Date();
  const streak = getStreak(data.dailyMissions, activeProfile.id);

  const handleToggleComplete = (missionId: string) => {
    toggleMissionComplete(missionId);
  };

  return (
    <div className="space-y-4">
      <section className="card border-sky-300">
        <p className="text-sm font-semibold text-sky-600">How&apos;s today?</p>
        <h2 className="mb-3 text-2xl font-bold text-purple-800">
          {formatDisplayDate(date)} 🌈
        </h2>

        {streak > 0 && (
          <p className="mb-3 inline-block rounded-full bg-orange-100 px-3 py-1 text-sm font-bold text-orange-600">
            🔥 {streak}-day streak!
          </p>
        )}

        <p className="mb-2 text-sm font-semibold text-purple-600">Weather</p>
        <div className="mb-4 flex flex-wrap gap-2">
          {WEATHER_OPTIONS.map((w) => (
            <button
              key={w.value}
              type="button"
              onClick={() => setWeather(w.value)}
              title={w.label}
              className={`rounded-xl px-3 py-2 text-2xl transition-transform active:scale-95 ${
                entry?.weather === w.value
                  ? "scale-110 bg-yellow-100 ring-2 ring-yellow-400"
                  : "bg-white/70 hover:bg-white"
              }`}
            >
              {w.icon}
            </button>
          ))}
        </div>

        <p className="mb-2 text-sm font-semibold text-purple-600">How do you feel?</p>
        <div className="flex flex-wrap gap-2">
          {MOOD_OPTIONS.map((m) => (
            <button
              key={m.value}
              type="button"
              onClick={() => setMood(m.value)}
              title={m.label}
              className={`rounded-xl px-3 py-2 text-2xl transition-transform active:scale-95 ${
                entry?.mood === m.value
                  ? "scale-110 bg-yellow-100 ring-2 ring-yellow-400"
                  : "bg-white/70 hover:bg-white"
              }`}
            >
              {m.icon}
            </button>
          ))}
        </div>
      </section>

      <section className="card border-purple-300">
        <h3 className="mb-3 text-lg font-bold text-purple-800">Pick your missions!</h3>
        {missions.length === 0 ? (
          <div className="rounded-xl bg-purple-50 p-4 text-center text-purple-600">
            <p>No missions yet!</p>
            <button
              type="button"
              onClick={() => setTab("missions")}
              className="mt-2 font-bold text-purple-700 underline"
            >
              Go to My Missions
            </button>
          </div>
        ) : (
          <div className="flex flex-wrap gap-2">
            {missions.map((mission) => {
              const selected = selectedIds.includes(mission.id);
              return (
                <button
                  key={mission.id}
                  type="button"
                  onClick={() => toggleMissionOnToday(mission.id)}
                  className={`rounded-full px-4 py-2 text-sm font-bold text-white shadow transition-all active:scale-95 ${
                    selected ? "opacity-50 ring-2 ring-white" : "hover:scale-105"
                  }`}
                  style={{ backgroundColor: mission.color }}
                >
                  {mission.icon} {mission.name}
                  {selected && " ⭐"}
                </button>
              );
            })}
          </div>
        )}
      </section>

      <section className="card border-yellow-400">
        <div className="mb-3 flex items-center justify-between">
          <h3 className="text-lg font-bold text-purple-800">Today&apos;s list</h3>
          {totalCount > 0 && (
            <span className="text-sm font-bold text-purple-600">
              {completedCount}/{totalCount} ⭐
            </span>
          )}
        </div>

        {allDone && (
          <div
            className={`celebrate-banner mb-4 rounded-2xl bg-gradient-to-r from-yellow-300 to-pink-400 p-4 text-center font-bold text-white shadow-lg ${
              justCompletedAll ? "celebrate-pop" : ""
            }`}
          >
            Super day! You earned all your stars! 🎉
          </div>
        )}

        {totalCount > 0 && (
          <div className="mb-4 h-3 overflow-hidden rounded-full bg-purple-100">
            <div
              className="h-full rounded-full bg-gradient-to-r from-yellow-400 to-orange-400 transition-all"
              style={{ width: `${(completedCount / totalCount) * 100}%` }}
            />
          </div>
        )}

        {todayMissions.length === 0 ? (
          <p className="rounded-xl bg-yellow-50 p-4 text-center text-purple-600">
            Tap a mission above to add it here!
          </p>
        ) : (
          <ul className="space-y-2">
            {todayMissions.map(({ missionId, mission, completed }) => (
              <li
                key={missionId}
                className={`flex items-center gap-3 rounded-xl border-2 bg-white/80 p-3 ${
                  completed ? "border-green-200 opacity-70" : "border-purple-100"
                }`}
              >
                <div className="flex-1">
                  <span
                    className={`font-bold text-purple-800 ${
                      completed ? "line-through" : ""
                    }`}
                  >
                    {mission.icon} {mission.name}
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => handleToggleComplete(missionId)}
                  className={`flex h-12 w-12 items-center justify-center rounded-xl text-2xl transition-transform active:scale-90 ${
                    completed
                      ? "bg-yellow-100"
                      : "border-2 border-dashed border-gray-300 bg-white"
                  }`}
                  aria-label={completed ? "Mark incomplete" : "Earn a star"}
                >
                  {completed ? "⭐" : "☆"}
                </button>
                <button
                  type="button"
                  onClick={() => removeFromToday(missionId)}
                  className="rounded-lg px-2 py-1 text-sm text-purple-400 hover:bg-purple-50 hover:text-purple-600"
                  aria-label="Remove from today"
                >
                  ✕
                </button>
              </li>
            ))}
          </ul>
        )}

      </section>
    </div>
  );
}
