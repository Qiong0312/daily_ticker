"use client";

import { useEffect, useMemo, useState } from "react";
import { useApp } from "@/context/AppProvider";
import { computeAchievements, groupAchievementsByCategory, sortAchievementsForDisplay, ACHIEVEMENT_CATEGORY_LABELS } from "@/lib/achievements";
import {
  formatDateKey,
  getDaysInMonth,
  parseDateKey,
  startOfMonth,
} from "@/lib/date-utils";
import {
  countStars,
  getActiveDaysInMonth,
  getDayRecap,
  getEarliestActivityMonth,
  getTopMissions,
} from "@/lib/stats";
import type { Achievement, Period } from "@/lib/types";
import { MOOD_OPTIONS, WEATHER_OPTIONS } from "@/lib/types";

const PERIODS: { id: Period; label: string }[] = [
  { id: "week", label: "This week" },
  { id: "month", label: "This month" },
  { id: "year", label: "This year" },
];

const TIER_COLORS: Record<Achievement["tier"], string> = {
  bronze: "from-orange-200 to-orange-300 border-orange-300",
  silver: "from-slate-200 to-slate-300 border-slate-400",
  gold: "from-yellow-300 to-amber-400 border-amber-500",
  locked: "from-gray-100 to-gray-200 border-gray-200",
};

const CATEGORY_ORDER: Achievement["category"][] = [
  "stars",
  "streak",
  "subject",
  "special",
];

export function WinsView() {
  const { activeProfile, data, getMissionsForProfile } = useApp();
  const [period, setPeriod] = useState<Period>("week");
  const [selectedDay, setSelectedDay] = useState<string | null>(null);
  const [calendarMonth, setCalendarMonth] = useState(() => startOfMonth(new Date()));

  const now = new Date();
  const profileId = activeProfile?.id;

  useEffect(() => {
    if (period === "month") {
      setCalendarMonth(startOfMonth(new Date()));
      setSelectedDay(null);
    }
  }, [period]);

  const displayMonth = period === "year" ? calendarMonth : startOfMonth(now);
  const calendarYear = displayMonth.getFullYear();
  const calendarMonthIndex = displayMonth.getMonth();

  const calendarDays = useMemo(() => {
    const daysInMonth = getDaysInMonth(calendarYear, calendarMonthIndex);
    const firstDay = new Date(calendarYear, calendarMonthIndex, 1).getDay();
    const offset = firstDay === 0 ? 6 : firstDay - 1;
    return { daysInMonth, offset, year: calendarYear, month: calendarMonthIndex };
  }, [calendarYear, calendarMonthIndex]);

  const earliestMonth = useMemo(() => {
    if (!profileId || !activeProfile) return startOfMonth(new Date());
    return getEarliestActivityMonth(
      data.dailyMissions,
      data.dailyEntries,
      profileId,
      parseDateKey(activeProfile.createdAt)
    );
  }, [data.dailyEntries, data.dailyMissions, profileId, activeProfile]);

  const currentMonth = startOfMonth(now);
  const canGoPrevMonth =
    period === "year" && displayMonth.getTime() > earliestMonth.getTime();
  const canGoNextMonth =
    period === "year" && displayMonth.getTime() < currentMonth.getTime();

  const goPrevMonth = () => {
    if (!canGoPrevMonth) return;
    setCalendarMonth(
      (prev) => new Date(prev.getFullYear(), prev.getMonth() - 1, 1)
    );
    setSelectedDay(null);
  };

  const goNextMonth = () => {
    if (!canGoNextMonth) return;
    setCalendarMonth(
      (prev) => new Date(prev.getFullYear(), prev.getMonth() + 1, 1)
    );
    setSelectedDay(null);
  };

  if (!activeProfile) return null;

  const missions = getMissionsForProfile(activeProfile.id);
  const stars = countStars(data.dailyMissions, activeProfile.id, period);
  const topMissions = getTopMissions(
    data.dailyMissions,
    missions,
    activeProfile.id,
    period
  );
  const topMission = topMissions[0]?.mission ?? null;
  const achievements = computeAchievements(
    data.dailyMissions,
    missions,
    activeProfile.id
  );
  const achievementGroups = groupAchievementsByCategory(achievements);

  const activeDays = getActiveDaysInMonth(
    data.dailyMissions,
    activeProfile.id,
    calendarYear,
    calendarMonthIndex
  );
  const maxCount = topMissions[0]?.count ?? 1;
  const periodLabel =
    period === "week"
      ? "this week"
      : period === "month"
        ? "this month"
        : "this year";
  const recapMissions = selectedDay
    ? getDayRecap(data.dailyMissions, missions, activeProfile.id, selectedDay)
    : [];
  const recapEntry = selectedDay
    ? data.dailyEntries.find(
        (e) => e.profileId === activeProfile.id && e.date === selectedDay
      )
    : undefined;

  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        {PERIODS.map((p) => (
          <button
            key={p.id}
            type="button"
            onClick={() => setPeriod(p.id)}
            className={`flex-1 rounded-xl py-2 text-sm font-bold transition-colors ${
              period === p.id
                ? "bg-yellow-300 text-purple-800 shadow"
                : "bg-white/70 text-purple-600 hover:bg-white"
            }`}
          >
            {p.label}
          </button>
        ))}
      </div>

      <section className="card border-yellow-400 text-center">
        <p className="text-sm font-semibold text-purple-600 capitalize">{periodLabel}</p>
        <p className="text-5xl font-bold text-purple-800">{stars} ⭐</p>
        {topMission && (
          <p className="mt-2 text-purple-600">
            Your #1 mission:{" "}
            <span className="font-bold">
              {topMission.icon} {topMission.name}
            </span>
          </p>
        )}
      </section>

      <section className="card border-purple-300">
        <h3 className="mb-4 text-lg font-bold text-purple-800">What you did most!</h3>
        {topMissions.length === 0 ? (
          <p className="text-center text-purple-500">
            Complete missions to see your stats here!
          </p>
        ) : (
          <ul className="space-y-3">
            {topMissions.map(({ mission, count }) => (
              <li key={mission.id}>
                <div className="mb-1 flex items-center justify-between">
                  <span className="font-bold text-purple-800">
                    {mission.icon} {mission.name}
                  </span>
                  <span className="font-bold text-purple-600">{count} ⭐</span>
                </div>
                <div className="h-4 overflow-hidden rounded-full bg-purple-100">
                  <div
                    className="h-full rounded-full transition-all"
                    style={{
                      width: `${(count / maxCount) * 100}%`,
                      backgroundColor: mission.color,
                    }}
                  />
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      {(period === "month" || period === "year") && (
        <section className="card border-sky-300">
          <div className="mb-3 flex items-center justify-between gap-2">
            {period === "year" ? (
              <button
                type="button"
                onClick={goPrevMonth}
                disabled={!canGoPrevMonth}
                aria-label="Previous month"
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-purple-100 text-lg font-bold text-purple-700 transition-colors hover:bg-purple-200 disabled:cursor-not-allowed disabled:opacity-30"
              >
                ‹
              </button>
            ) : (
              <span className="w-9" aria-hidden />
            )}
            <h3 className="flex-1 text-center text-lg font-bold text-purple-800">
              {displayMonth.toLocaleDateString("en-US", {
                month: "long",
                year: "numeric",
              })}
            </h3>
            {period === "year" ? (
              <button
                type="button"
                onClick={goNextMonth}
                disabled={!canGoNextMonth}
                aria-label="Next month"
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-purple-100 text-lg font-bold text-purple-700 transition-colors hover:bg-purple-200 disabled:cursor-not-allowed disabled:opacity-30"
              >
                ›
              </button>
            ) : (
              <span className="w-9" aria-hidden />
            )}
          </div>
          <div className="mb-1 grid grid-cols-7 gap-1 text-center text-xs font-bold text-purple-500">
            {["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"].map((d) => (
              <span key={d}>{d}</span>
            ))}
          </div>
          <div className="grid grid-cols-7 gap-1">
            {Array.from({ length: calendarDays.offset }).map((_, i) => (
              <div key={`empty-${i}`} />
            ))}
            {Array.from({ length: calendarDays.daysInMonth }).map((_, i) => {
              const day = i + 1;
              const dateKey = formatDateKey(new Date(calendarDays.year, calendarDays.month, day));
              const hasStar = activeDays.has(day);
              return (
                <button
                  key={day}
                  type="button"
                  disabled={!hasStar}
                  onClick={() => hasStar && setSelectedDay(dateKey)}
                  className={`aspect-square rounded-lg text-sm font-bold transition-colors ${
                    hasStar
                      ? "bg-yellow-100 text-purple-800 hover:bg-yellow-200"
                      : "text-purple-300"
                  } ${selectedDay === dateKey ? "ring-2 ring-purple-500" : ""}`}
                >
                  {hasStar ? "⭐" : day}
                </button>
              );
            })}
          </div>
        </section>
      )}

      {selectedDay && (
        <section className="card border-pink-300">
          <div className="mb-2 flex items-center justify-between">
            <h3 className="text-lg font-bold text-purple-800">
              {parseDateKey(selectedDay).toLocaleDateString("en-US", {
                weekday: "long",
                month: "long",
                day: "numeric",
              })}
            </h3>
            <button
              type="button"
              onClick={() => setSelectedDay(null)}
              className="text-purple-400 hover:text-purple-600"
            >
              ✕
            </button>
          </div>
          {recapEntry?.weather && (
            <p className="text-sm text-purple-600">
              Weather:{" "}
              {WEATHER_OPTIONS.find((w) => w.value === recapEntry.weather)?.icon}
            </p>
          )}
          {recapEntry?.mood && (
            <p className="text-sm text-purple-600">
              Mood: {MOOD_OPTIONS.find((m) => m.value === recapEntry.mood)?.icon}
            </p>
          )}
          {recapMissions.length === 0 ? (
            <p className="text-purple-500">No completed missions this day.</p>
          ) : (
            <ul className="mt-2 space-y-1">
              {recapMissions.map((m) => (
                <li key={m.id} className="font-bold text-purple-800">
                  ⭐ {m.icon} {m.name}
                </li>
              ))}
            </ul>
          )}
        </section>
      )}

      {CATEGORY_ORDER.map((category) => {
        const items = sortAchievementsForDisplay(achievementGroups[category]);
        if (items.length === 0) return null;
        const label = ACHIEVEMENT_CATEGORY_LABELS[category];
        const gridClass =
          category === "subject"
            ? "grid grid-cols-2 gap-3"
            : "grid grid-cols-1 gap-3 sm:grid-cols-2";

        return (
          <section key={category} className="card border-orange-300">
            <h3 className="mb-1 text-lg font-bold text-purple-800">
              {label.icon} {label.title}
            </h3>
            <p className="mb-4 text-xs text-purple-500">
              {category === "stars" && "Earn more stars each week, month, and year"}
              {category === "streak" && "Keep showing up — streaks take real dedication"}
              {category === "subject" && "Level up each mission from Explorer to Champion"}
              {category === "special" && "Bonus badges for big days and variety"}
            </p>
            <div className={gridClass}>
              {items.map((a) => (
                <AchievementCard key={a.id} achievement={a} />
              ))}
            </div>
          </section>
        );
      })}
    </div>
  );
}

function AchievementCard({ achievement }: { achievement: Achievement }) {
  const { tier, unlocked, progress, target, icon, title, description } =
    achievement;
  const progressPct = target > 0 ? Math.min(100, (progress / target) * 100) : 0;

  return (
    <div
      className={`rounded-2xl border-2 bg-gradient-to-br p-4 ${
        unlocked ? TIER_COLORS[tier] : `${TIER_COLORS.locked} opacity-80`
      }`}
    >
      <div className="flex items-start gap-3">
        <span className={`text-3xl ${unlocked ? "" : "grayscale opacity-50"}`}>
          {icon}
        </span>
        <div className="min-w-0 flex-1">
          <p className="font-bold text-purple-900">{title}</p>
          <p className="text-xs text-purple-700">{description}</p>
          {unlocked ? (
            <span className="mt-1 inline-block rounded-full bg-white/60 px-2 py-0.5 text-xs font-bold capitalize text-green-700">
              {tier} unlocked
            </span>
          ) : (
            <span className="mt-1 inline-block text-xs font-semibold text-purple-500">
              Keep going!
            </span>
          )}
        </div>
      </div>
      {tier !== "gold" && (
        <div className="mt-3 h-2 overflow-hidden rounded-full bg-white/60">
          <div
            className="h-full rounded-full bg-gradient-to-r from-purple-400 to-pink-400 transition-all"
            style={{ width: `${progressPct}%` }}
          />
        </div>
      )}
    </div>
  );
}
