import type { Mission } from "./types";

export const DEFAULT_MISSIONS: Omit<Mission, "id" | "profileId" | "sortOrder">[] = [
  { name: "English", icon: "📖", color: "#4ECDC4" },
  { name: "Chinese", icon: "🀄", color: "#FF6B6B" },
  { name: "Maths", icon: "🔢", color: "#A78BFA" },
  { name: "STS", icon: "🔬", color: "#51CF66" },
  { name: "Taekwondo", icon: "🥋", color: "#FFE66D" },
  { name: "Piano", icon: "🎹", color: "#FF8FAB" },
];
