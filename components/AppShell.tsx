"use client";

import { useRef } from "react";
import { useApp } from "@/context/AppProvider";
import { TodayView } from "@/components/TodayView";
import { MissionsView } from "@/components/MissionsView";
import { WinsView } from "@/components/WinsView";
import { OverlayScrollbar } from "@/components/OverlayScrollbar";
import { ProfileSwitchButton } from "@/components/ProfileSwitchButton";
import { BottomNavTab } from "@/components/BottomNav";
import type { Tab } from "@/lib/types";

const TABS: { id: Tab; label: string }[] = [
  { id: "today", label: "Today" },
  { id: "wins", label: "My Wins" },
  { id: "missions", label: "Missions" },
];

export function AppShell() {
  const { activeProfile, tab, setTab, openProfilePicker } = useApp();
  const mainRef = useRef<HTMLElement>(null);

  if (!activeProfile) return null;

  return (
    <div className="mx-auto flex h-dvh max-w-lg flex-col overflow-hidden bg-gradient-to-b from-sky-300 via-sky-200 to-yellow-200">
      <header className="flex shrink-0 items-center justify-between px-4 pb-2 pt-6">
        <div className="flex items-center gap-3">
          <span className="text-3xl">{activeProfile.avatar}</span>
          <div>
            <p className="text-sm text-purple-600">Hi there!</p>
            <p className="text-xl font-bold text-purple-800">{activeProfile.name}</p>
          </div>
        </div>
        <ProfileSwitchButton onClick={openProfilePicker} />
      </header>

      <div className="relative min-h-0 flex-1">
        <main
          ref={mainRef}
          className="scrollbar-hidden h-full overflow-y-auto px-4 pb-24 pt-2"
        >
          {tab === "today" && <TodayView />}
          {tab === "wins" && <WinsView />}
          {tab === "missions" && <MissionsView />}
        </main>
        <OverlayScrollbar targetRef={mainRef} contentKey={tab} />
      </div>

      <nav className="fixed bottom-0 left-0 right-0 z-20 mx-auto max-w-lg border-t-2 border-purple-100/80 bg-white/92 px-2 py-2 backdrop-blur-md">
        <div className="flex justify-around gap-1">
          {TABS.map((t) => (
            <BottomNavTab
              key={t.id}
              id={t.id}
              label={t.label}
              active={tab === t.id}
              onClick={() => setTab(t.id)}
            />
          ))}
        </div>
      </nav>
    </div>
  );
}
