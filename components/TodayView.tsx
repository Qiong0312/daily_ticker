"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useApp } from "@/context/AppProvider";
import { formatDisplayDate, todayKey } from "@/lib/date-utils";
import { missionTint } from "@/lib/color-utils";
import { getStreak } from "@/lib/stats";
import { MOOD_OPTIONS, WEATHER_OPTIONS, type Mission } from "@/lib/types";

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
      <section className="card border-sky-300 p-3">
        <div className="mb-2 flex flex-wrap items-center justify-between gap-x-3 gap-y-1">
          <div>
            <p className="text-xs font-semibold text-sky-600">How&apos;s today?</p>
            <p className="text-base font-bold text-purple-800">{formatDisplayDate(date)}</p>
          </div>
          {streak > 0 && (
            <span className="rounded-full bg-orange-100 px-2 py-0.5 text-xs font-bold text-orange-600">
              🔥 {streak}-day streak
            </span>
          )}
        </div>

        <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
          <div>
            <p className="mb-1 text-[11px] font-semibold text-purple-500">Weather</p>
            <div className="flex flex-wrap gap-1">
              {WEATHER_OPTIONS.map((w) => (
                <button
                  key={w.value}
                  type="button"
                  onClick={() => setWeather(w.value)}
                  title={w.label}
                  className={`rounded-lg px-1.5 py-0.5 text-lg transition-transform active:scale-95 ${
                    entry?.weather === w.value
                      ? "bg-yellow-100 ring-2 ring-yellow-400"
                      : "bg-white/70 hover:bg-white"
                  }`}
                >
                  {w.icon}
                </button>
              ))}
            </div>
          </div>

          <div>
            <p className="mb-1 text-[11px] font-semibold text-purple-500">Feel</p>
            <div className="flex flex-wrap gap-1">
              {MOOD_OPTIONS.map((m) => (
                <button
                  key={m.value}
                  type="button"
                  onClick={() => setMood(m.value)}
                  title={m.label}
                  className={`rounded-lg px-1.5 py-0.5 text-lg transition-transform active:scale-95 ${
                    entry?.mood === m.value
                      ? "bg-yellow-100 ring-2 ring-yellow-400"
                      : "bg-white/70 hover:bg-white"
                  }`}
                >
                  {m.icon}
                </button>
              ))}
            </div>
          </div>
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
          <ul className="space-y-3">
            {todayMissions.map(({ missionId, mission, completed }) => (
              <TodayMissionRow
                key={missionId}
                mission={mission}
                completed={completed}
                onToggle={() => handleToggleComplete(missionId)}
                onRemove={() => removeFromToday(missionId)}
              />
            ))}
          </ul>
        )}

      </section>
    </div>
  );
}

function TodayMissionRow({
  mission,
  completed,
  onToggle,
  onRemove,
}: {
  mission: Mission;
  completed: boolean;
  onToggle: () => void;
  onRemove: () => void;
}) {
  return (
    <li
      className={`relative overflow-hidden rounded-2xl border-2 transition-all duration-300 ${
        completed ? "border-amber-300/80 shadow-md" : "border-transparent shadow-sm"
      }`}
      style={{
        backgroundColor: completed
          ? missionTint(mission.color, 22)
          : missionTint(mission.color, 38),
      }}
    >
      <div
        className="absolute bottom-0 left-0 top-0 w-1.5"
        style={{ backgroundColor: mission.color }}
        aria-hidden
      />

      <div className="flex items-center gap-3 p-3 pl-4">
        <div className="relative shrink-0">
          <span
            className={`flex h-11 w-11 items-center justify-center rounded-xl text-xl text-white shadow-sm transition-transform duration-300 ${
              completed ? "scale-95 ring-2 ring-amber-300 ring-offset-1" : ""
            }`}
            style={{ backgroundColor: mission.color }}
          >
            {mission.icon}
          </span>
          {completed && (
            <span className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-amber-300 text-xs shadow">
              ✓
            </span>
          )}
        </div>

        <div className="min-w-0 flex-1">
          <p className="truncate font-bold text-purple-900">{mission.name}</p>
          {completed ? (
            <span className="mt-0.5 inline-flex items-center gap-1 rounded-full bg-amber-100/90 px-2 py-0.5 text-xs font-bold text-amber-700">
              Star earned! ✨
            </span>
          ) : (
            <span className="mt-0.5 text-xs font-semibold text-purple-600/80">
              Tap the star when done
            </span>
          )}
        </div>

        <button
          type="button"
          onClick={onToggle}
          className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-xl text-2xl transition-all duration-300 active:scale-90 ${
            completed
              ? "bg-amber-100 shadow-inner ring-2 ring-amber-300"
              : "border-2 border-dashed bg-white/80"
          }`}
          style={
            completed ? undefined : { borderColor: missionTint(mission.color, 55) }
          }
          aria-label={completed ? "Mark incomplete" : "Earn a star"}
        >
          {completed ? "⭐" : "☆"}
        </button>

        <button
          type="button"
          onClick={onRemove}
          className="shrink-0 rounded-lg px-1.5 py-1 text-sm text-purple-400/80 transition-colors hover:bg-white/60 hover:text-purple-600"
          aria-label="Remove from today"
        >
          ✕
        </button>
      </div>
    </li>
  );
}
