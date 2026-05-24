"use client";

import { useApp } from "@/context/AppProvider";
import { TodayView } from "@/components/TodayView";
import { MissionsView } from "@/components/MissionsView";
import { WinsView } from "@/components/WinsView";

const TABS = [
  { id: "today" as const, label: "Today", icon: "🏠" },
  { id: "wins" as const, label: "My Wins", icon: "⭐" },
  { id: "missions" as const, label: "Missions", icon: "🎯" },
];

export function AppShell() {
  const { activeProfile, tab, setTab, openProfilePicker } = useApp();

  if (!activeProfile) return null;

  return (
    <div className="mx-auto flex min-h-screen max-w-lg flex-col bg-gradient-to-b from-sky-300 via-sky-200 to-yellow-200">
      <header className="flex items-center justify-between px-4 pb-2 pt-6">
        <div className="flex items-center gap-3">
          <span className="text-3xl">{activeProfile.avatar}</span>
          <div>
            <p className="text-sm text-purple-600">Hi there!</p>
            <p className="text-xl font-bold text-purple-800">{activeProfile.name}</p>
          </div>
        </div>
        <button
          type="button"
          onClick={openProfilePicker}
          className="rounded-xl bg-white/80 px-3 py-2 text-sm font-bold text-purple-700 shadow"
        >
          Switch 👤
        </button>
      </header>

      <main className="flex-1 overflow-y-auto px-4 pb-24 pt-2">
        {tab === "today" && <TodayView />}
        {tab === "wins" && <WinsView />}
        {tab === "missions" && <MissionsView />}
      </main>

      <nav className="fixed bottom-0 left-0 right-0 mx-auto max-w-lg border-t-2 border-white/50 bg-white/90 backdrop-blur-md">
        <div className="flex justify-around px-2 py-2">
          {TABS.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setTab(t.id)}
              className={`flex flex-1 flex-col items-center gap-0.5 rounded-xl py-2 transition-colors ${
                tab === t.id
                  ? "bg-yellow-100 text-purple-800"
                  : "text-purple-500 hover:bg-purple-50"
              }`}
            >
              <span className="text-2xl">{t.icon}</span>
              <span className="text-xs font-bold">{t.label}</span>
            </button>
          ))}
        </div>
      </nav>
    </div>
  );
}
