"use client";

import { ProfilePicker } from "@/components/ProfilePicker";
import { AppShell } from "@/components/AppShell";
import { useApp } from "@/context/AppProvider";

export function DailyTickerApp() {
  const { ready, activeProfile } = useApp();

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-b from-sky-300 to-yellow-200">
        <p className="animate-pulse text-xl font-bold text-purple-700">Loading...</p>
      </div>
    );
  }

  return (
    <>
      <ProfilePicker />
      {activeProfile && <AppShell />}
    </>
  );
}
