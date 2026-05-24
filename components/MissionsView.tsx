"use client";

import { useState } from "react";
import { useApp } from "@/context/AppProvider";
import {
  DEFAULT_WEEKLY_GOAL,
  getWeeklyGoal,
  MAX_WEEKLY_GOAL,
  MIN_WEEKLY_GOAL,
} from "@/lib/mission-utils";
import {
  MISSION_COLORS,
  MISSION_ICONS,
  type Mission,
} from "@/lib/types";

export function MissionsView() {
  const {
    activeProfile,
    getMissionsForProfile,
    addMission,
    updateMission,
    deleteMission,
    reorderMissions,
  } = useApp();
  const [editing, setEditing] = useState<Mission | null>(null);
  const [adding, setAdding] = useState(false);
  const [dragId, setDragId] = useState<string | null>(null);

  if (!activeProfile) return null;

  const missions = getMissionsForProfile(activeProfile.id);

  const handleDragStart = (id: string) => setDragId(id);

  const handleDragOver = (e: React.DragEvent, targetId: string) => {
    e.preventDefault();
    if (!dragId || dragId === targetId) return;
    const ids = missions.map((m) => m.id);
    const from = ids.indexOf(dragId);
    const to = ids.indexOf(targetId);
    if (from < 0 || to < 0) return;
    ids.splice(from, 1);
    ids.splice(to, 0, dragId);
    reorderMissions(ids);
  };

  const handleDelete = (mission: Mission) => {
    const ok = window.confirm(
      `Remove ${mission.name} from your missions? Your old stars stay in My Wins.`
    );
    if (ok) deleteMission(mission.id);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold text-purple-800">My Missions</h2>
        <button
          type="button"
          onClick={() => {
            setAdding(true);
            setEditing(null);
          }}
          className="rounded-xl bg-gradient-to-r from-orange-400 to-pink-500 px-4 py-2 font-bold text-white shadow"
        >
          + Add
        </button>
      </div>

      <p className="text-sm text-purple-600">
        Create and edit your mission bubbles. Set a weekly star goal for each one!
      </p>

      <ul className="space-y-2">
        {missions.map((mission) => (
          <li
            key={mission.id}
            draggable
            onDragStart={() => handleDragStart(mission.id)}
            onDragOver={(e) => handleDragOver(e, mission.id)}
            onDragEnd={() => setDragId(null)}
            className="flex items-center gap-3 rounded-xl border-2 border-purple-100 bg-white/90 p-3 shadow-sm"
          >
            <span className="cursor-grab text-purple-300 active:cursor-grabbing">⠿</span>
            <span
              className="flex h-10 w-10 items-center justify-center rounded-full text-xl text-white"
              style={{ backgroundColor: mission.color }}
            >
              {mission.icon}
            </span>
            <div className="min-w-0 flex-1">
              <p className="font-bold text-purple-800">{mission.name}</p>
              <p className="text-xs font-semibold text-purple-500">
                {getWeeklyGoal(mission)}⭐ weekly goal
              </p>
            </div>
            <button
              type="button"
              onClick={() => {
                setEditing(mission);
                setAdding(false);
              }}
              className="rounded-lg bg-purple-100 px-3 py-1 text-sm font-bold text-purple-700"
            >
              Edit
            </button>
            <button
              type="button"
              onClick={() => handleDelete(mission)}
              className="rounded-lg bg-red-100 px-3 py-1 text-sm font-bold text-red-600"
            >
              Remove
            </button>
          </li>
        ))}
      </ul>

      {missions.length === 0 && (
        <p className="rounded-xl bg-purple-50 p-6 text-center text-purple-600">
          No missions yet — tap Add to create your first one!
        </p>
      )}

      {(adding || editing) && (
        <MissionForm
          mission={editing}
          onSave={(data) => {
            if (editing) {
              updateMission(editing.id, data);
            } else {
              addMission(data);
            }
            setAdding(false);
            setEditing(null);
          }}
          onCancel={() => {
            setAdding(false);
            setEditing(null);
          }}
        />
      )}
    </div>
  );
}

function MissionForm({
  mission,
  onSave,
  onCancel,
}: {
  mission: Mission | null;
  onSave: (data: {
    name: string;
    icon: string;
    color: string;
    weeklyGoal: number;
  }) => void;
  onCancel: () => void;
}) {
  const [name, setName] = useState(mission?.name ?? "");
  const [icon, setIcon] = useState(mission?.icon ?? MISSION_ICONS[0]);
  const [color, setColor] = useState(mission?.color ?? MISSION_COLORS[0]);
  const [weeklyGoal, setWeeklyGoal] = useState(
    mission ? getWeeklyGoal(mission) : DEFAULT_WEEKLY_GOAL
  );

  return (
    <div className="fixed inset-0 z-40 flex items-end justify-center bg-purple-900/30 p-4 backdrop-blur-sm sm:items-center">
      <div className="w-full max-w-md rounded-3xl border-4 border-yellow-300 bg-white p-6 shadow-2xl">
        <h3 className="mb-4 text-xl font-bold text-purple-800">
          {mission ? "Edit mission" : "New mission"}
        </h3>

        <label className="mb-4 block">
          <span className="text-sm font-semibold text-purple-700">Name</span>
          <input
            type="text"
            maxLength={20}
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="mt-1 w-full rounded-xl border-2 border-purple-200 px-4 py-3 text-lg focus:border-purple-400 focus:outline-none"
            placeholder="Mission name"
          />
        </label>

        <p className="mb-2 text-sm font-semibold text-purple-700">Icon</p>
        <div className="mb-4 grid max-h-36 grid-cols-8 gap-1.5 overflow-y-auto p-1">
          {MISSION_ICONS.map((i) => (
            <button
              key={i}
              type="button"
              onClick={() => setIcon(i)}
              className={`rounded-lg p-1 text-xl ${
                icon === i
                  ? "bg-yellow-100 ring-2 ring-yellow-400 ring-offset-1"
                  : "hover:bg-purple-50"
              }`}
            >
              {i}
            </button>
          ))}
        </div>

        <p className="mb-2 text-sm font-semibold text-purple-700">Color</p>
        <div className="flex flex-wrap gap-2">
          {MISSION_COLORS.map((c) => (
            <button
              key={c}
              type="button"
              onClick={() => setColor(c)}
              className={`h-10 w-10 rounded-full transition-transform ${
                color === c ? "scale-110 ring-2 ring-purple-600 ring-offset-2" : ""
              }`}
              style={{ backgroundColor: c }}
              aria-label={`Color ${c}`}
            />
          ))}
        </div>

        <p className="mb-2 mt-4 text-sm font-semibold text-purple-700">Weekly star goal</p>
        <p className="mb-2 text-xs text-purple-500">
          How many stars to aim for each week?
        </p>
        <div className="mb-4 flex flex-wrap gap-2">
          {Array.from(
            { length: MAX_WEEKLY_GOAL - MIN_WEEKLY_GOAL + 1 },
            (_, i) => i + MIN_WEEKLY_GOAL
          ).map((n) => (
            <button
              key={n}
              type="button"
              onClick={() => setWeeklyGoal(n)}
              className={`min-w-[2.75rem] rounded-xl px-3 py-2 text-sm font-bold transition-colors ${
                weeklyGoal === n
                  ? "bg-yellow-100 ring-2 ring-yellow-400 text-purple-800"
                  : "bg-purple-50 text-purple-600 hover:bg-purple-100"
              }`}
            >
              {n}⭐
            </button>
          ))}
        </div>

        <div className="mt-6 flex gap-3">
          <button
            type="button"
            onClick={onCancel}
            className="flex-1 rounded-xl border-2 border-purple-200 py-3 font-bold text-purple-600"
          >
            Cancel
          </button>
          <button
            type="button"
            disabled={!name.trim()}
            onClick={() =>
              onSave({ name: name.trim(), icon, color, weeklyGoal })
            }
            className="flex-1 rounded-xl bg-gradient-to-r from-orange-400 to-pink-500 py-3 font-bold text-white shadow disabled:opacity-50"
          >
            Save mission
          </button>
        </div>
      </div>
    </div>
  );
}
