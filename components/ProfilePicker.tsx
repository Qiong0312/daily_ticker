"use client";

import { useState } from "react";
import { useApp } from "@/context/AppProvider";
import { AVATAR_OPTIONS } from "@/lib/types";

export function ProfilePicker() {
  const {
    data,
    activeProfile,
    createProfile,
    switchProfile,
    closeProfilePicker,
    showProfilePicker,
  } = useApp();
  const [name, setName] = useState("");
  const [avatar, setAvatar] = useState(AVATAR_OPTIONS[0]);
  const [adding, setAdding] = useState(false);

  const showPicker =
    !activeProfile || showProfilePicker || data.profiles.length === 0;

  if (!showPicker) return null;

  const isAddingNew = adding || data.profiles.length === 0;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-purple-900/40 p-4 backdrop-blur-sm">
      <ProfileCard>
        <h1 className="mb-2 text-center text-2xl font-bold text-purple-700">
          {isAddingNew ? "Create your profile" : "Who's using the app?"}
        </h1>
        <p className="mb-6 text-center text-sm text-purple-500">
          {isAddingNew
            ? "Pick a name and avatar to get started!"
            : "Tap a profile to switch"}
        </p>

        {!isAddingNew && (
          <div className="grid grid-cols-3 gap-3">
            {data.profiles.map((profile) => (
              <ProfileButton
                key={profile.id}
                onClick={() => switchProfile(profile.id)}
                active={profile.id === activeProfile?.id}
              >
                <span className="text-4xl">{profile.avatar}</span>
                <span className="font-bold text-purple-800">{profile.name}</span>
              </ProfileButton>
            ))}
            <ProfileButton onClick={() => setAdding(true)}>
              <span className="text-4xl">➕</span>
              <span className="font-bold text-purple-800">Add profile</span>
            </ProfileButton>
          </div>
        )}

        {isAddingNew && (
          <div className="space-y-4">
            <label className="block">
              <span className="text-sm font-semibold text-purple-700">Your name</span>
              <input
                type="text"
                maxLength={12}
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Alex"
                className="mt-1 w-full rounded-xl border-2 border-purple-200 px-4 py-3 text-lg focus:border-purple-400 focus:outline-none"
              />
            </label>

            <div className="grid grid-cols-5 gap-2">
              {AVATAR_OPTIONS.map((a) => (
                <button
                  key={a}
                  type="button"
                  onClick={() => setAvatar(a)}
                  className={`rounded-xl py-2 text-2xl transition-transform active:scale-95 ${
                    avatar === a
                      ? "scale-105 bg-yellow-100 ring-2 ring-yellow-400"
                      : "bg-purple-50 hover:bg-purple-100"
                  }`}
                >
                  {a}
                </button>
              ))}
            </div>

            <div className="flex gap-3 pt-2">
              {data.profiles.length > 0 && (
                <button
                  type="button"
                  onClick={() => setAdding(false)}
                  className="flex-1 rounded-xl border-2 border-purple-200 py-3 font-bold text-purple-600"
                >
                  Back
                </button>
              )}
              <button
                type="button"
                disabled={!name.trim()}
                onClick={() => createProfile(name, avatar)}
                className="flex-1 rounded-xl bg-gradient-to-r from-orange-400 to-pink-500 py-3 font-bold text-white shadow-lg disabled:opacity-50"
              >
                Let&apos;s go!
              </button>
            </div>
          </div>
        )}

        {!isAddingNew && data.profiles.length > 0 && (
          <button
            type="button"
            onClick={closeProfilePicker}
            className="mt-6 w-full rounded-xl border-2 border-purple-200 py-3 font-bold text-purple-600"
          >
            Cancel
          </button>
        )}
      </ProfileCard>
    </div>
  );
}

function ProfileButton({
  children,
  onClick,
  active,
}: {
  children: React.ReactNode;
  onClick: () => void;
  active?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex flex-col items-center justify-center gap-1 rounded-2xl border-2 py-4 transition-transform active:scale-95 ${
        active
          ? "scale-105 border-yellow-400 bg-yellow-100 shadow-md"
          : "border-purple-100 bg-purple-50 hover:bg-purple-100"
      }`}
    >
      {children}
    </button>
  );
}

function ProfileCard({ children }: { children: React.ReactNode }) {
  return (
    <div className="w-full max-w-md rounded-3xl border-4 border-yellow-300 bg-white p-6 shadow-2xl">
      {children}
    </div>
  );
}

