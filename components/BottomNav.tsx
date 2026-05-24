import type { ComponentType } from "react";
import type { Tab } from "@/lib/types";

interface NavIconProps {
  active?: boolean;
}

export function TodayNavIcon({ active }: NavIconProps) {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M4 10.5 12 4l8 6.5V19a1.5 1.5 0 0 1-1.5 1.5H14v-5.5H10V20.5H5.5A1.5 1.5 0 0 1 4 19V10.5Z"
        fill={active ? "#FDE68A" : "#BAE6FD"}
        stroke="#7C3AED"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <path
        d="M9.5 6.5h5L12 4.2 9.5 6.5Z"
        fill="#FBCFE8"
        stroke="#A855F7"
        strokeWidth="1.2"
        strokeLinejoin="round"
      />
      <rect x="10" y="13" width="4" height="4" rx="0.8" fill="#FFF7ED" stroke="#A855F7" strokeWidth="1" />
      <circle cx="11.1" cy="14.3" r="0.45" fill="#7C3AED" />
      <circle cx="12.9" cy="14.3" r="0.45" fill="#7C3AED" />
      <path d="M11 15.4c.5.4 1.5.4 2 0" stroke="#EC4899" strokeWidth="0.8" strokeLinecap="round" />
      <circle cx="17.5" cy="8" r="1" fill="#FBCFE8" stroke="#EC4899" strokeWidth="0.8" />
    </svg>
  );
}

export function WinsNavIcon({ active }: NavIconProps) {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M12 3.5 14.2 9h5.3l-4.3 3.2 1.6 5.1L12 15.8 7.2 17.3l1.6-5.1-4.3-3.2h5.3L12 3.5Z"
        fill={active ? "#FDE68A" : "#FBCFE8"}
        stroke="#A855F7"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <circle cx="12" cy="11.5" r="0.55" fill="#7C3AED" />
      <circle cx="10.4" cy="10.8" r="0.45" fill="#7C3AED" />
      <circle cx="13.6" cy="10.8" r="0.45" fill="#7C3AED" />
      <path d="M10.8 12.6c.8.5 1.9.5 2.7 0" stroke="#EC4899" strokeWidth="0.9" strokeLinecap="round" />
      <path
        d="M5 5.5 6.2 7M19 5.5 17.8 7M12 2v1.2"
        stroke="#EC4899"
        strokeWidth="1.2"
        strokeLinecap="round"
      />
    </svg>
  );
}

export function MissionsNavIcon({ active }: NavIconProps) {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden>
      <circle cx="12" cy="12" r="7.5" fill={active ? "#BAE6FD" : "#E9D5FF"} stroke="#7C3AED" strokeWidth="1.5" />
      <circle cx="12" cy="12" r="4.5" fill="#FFF7ED" stroke="#A855F7" strokeWidth="1.2" />
      <circle cx="12" cy="12" r="1.6" fill="#FBCFE8" stroke="#EC4899" strokeWidth="1" />
      <path
        d="M12 4.5v2M12 17.5v2M4.5 12h2M17.5 12h2"
        stroke="#EC4899"
        strokeWidth="1.3"
        strokeLinecap="round"
      />
      <path
        d="M6.8 6.8l1.4 1.4M15.8 15.8l1.4 1.4M17.2 6.8l-1.4 1.4M8.2 15.8l-1.4 1.4"
        stroke="#F472B6"
        strokeWidth="1"
        strokeLinecap="round"
      />
      <circle cx="10.3" cy="11.2" r="0.4" fill="#7C3AED" />
      <circle cx="13.7" cy="11.2" r="0.4" fill="#7C3AED" />
    </svg>
  );
}

const NAV_ICONS: Record<Tab, ComponentType<NavIconProps>> = {
  today: TodayNavIcon,
  wins: WinsNavIcon,
  missions: MissionsNavIcon,
};

interface BottomNavTabProps {
  id: Tab;
  label: string;
  active: boolean;
  onClick: () => void;
}

export function BottomNavTab({ id, label, active, onClick }: BottomNavTabProps) {
  const Icon = NAV_ICONS[id];

  return (
    <button
      type="button"
      onClick={onClick}
      aria-current={active ? "page" : undefined}
      className={`flex flex-1 flex-col items-center gap-1 rounded-2xl py-1.5 transition-all active:scale-95 ${
        active ? "text-purple-800" : "text-purple-500 hover:bg-purple-50/80"
      }`}
    >
      <span
        className={`flex h-10 w-10 items-center justify-center rounded-full border-2 transition-all ${
          active
            ? "border-amber-300 bg-gradient-to-br from-yellow-100 via-amber-100 to-pink-100 shadow-sm ring-2 ring-amber-200/80"
            : "border-purple-100 bg-gradient-to-br from-sky-50 via-purple-50 to-pink-50"
        }`}
      >
        <Icon active={active} />
      </span>
      <span className="text-xs font-bold">{label}</span>
    </button>
  );
}
