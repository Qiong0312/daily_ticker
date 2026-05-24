interface ProfileSwitchButtonProps {
  onClick: () => void;
}

export function ProfileSwitchButton({ onClick }: ProfileSwitchButtonProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label="Switch profile"
      className="group flex items-center gap-2 rounded-full border-2 border-purple-200 bg-white/95 py-1.5 pl-1.5 pr-3.5 text-sm font-bold text-purple-700 shadow-sm transition-transform active:scale-95 hover:border-purple-300 hover:bg-purple-50"
    >
      <span className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-sky-100 via-purple-100 to-pink-100 shadow-inner">
        <SwitchProfilesIcon />
      </span>
      Switch
    </button>
  );
}

function SwitchProfilesIcon() {
  return (
    <svg
      width="22"
      height="22"
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden
      className="text-purple-600"
    >
      <circle cx="8.5" cy="9" r="4.5" fill="#FBCFE8" stroke="#A855F7" strokeWidth="1.5" />
      <circle cx="15.5" cy="15" r="4.5" fill="#BAE6FD" stroke="#7C3AED" strokeWidth="1.5" />
      <circle cx="7" cy="8" r="0.9" fill="#7C3AED" />
      <circle cx="10" cy="8" r="0.9" fill="#7C3AED" />
      <path
        d="M6.5 10.5c0 0 1.2 1.8 2 2.2"
        stroke="#7C3AED"
        strokeWidth="1"
        strokeLinecap="round"
      />
      <circle cx="14" cy="14" r="0.9" fill="#6D28D9" />
      <circle cx="17" cy="14" r="0.9" fill="#6D28D9" />
      <path
        d="M13.5 16.5c0 0 1.2 1.2 2.2 1.2"
        stroke="#6D28D9"
        strokeWidth="1"
        strokeLinecap="round"
      />
      <path
        d="M12 4.5l1.8 1.8M12 4.5l-1.8 1.8M12 4.5V7"
        stroke="#EC4899"
        strokeWidth="1.6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M12 19.5l1.8-1.8M12 19.5l-1.8-1.8M12 19.5V17"
        stroke="#EC4899"
        strokeWidth="1.6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
