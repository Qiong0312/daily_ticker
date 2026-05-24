export type Weather =
  | "sunny"
  | "partly-cloudy"
  | "cloudy"
  | "rainy"
  | "thunderstorm";
export type Mood = "happy" | "okay" | "tired" | "frustrated" | "excited";
export type Tab = "today" | "wins" | "missions";
export type Period = "week" | "month" | "year";

export interface Profile {
  id: string;
  name: string;
  avatar: string;
  createdAt: string;
}

export interface Mission {
  id: string;
  profileId: string;
  name: string;
  icon: string;
  color: string;
  sortOrder: number;
}

export interface DailyEntry {
  profileId: string;
  date: string;
  weather?: Weather;
  mood?: Mood;
}

export interface DailyMission {
  profileId: string;
  date: string;
  missionId: string;
  completed: boolean;
  completedAt?: string;
}

export interface AppData {
  profiles: Profile[];
  activeProfileId: string | null;
  missions: Mission[];
  dailyEntries: DailyEntry[];
  dailyMissions: DailyMission[];
}

export type AchievementCategory = "stars" | "streak" | "subject" | "special";

export interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: string;
  category: AchievementCategory;
  tier: "bronze" | "silver" | "gold" | "locked";
  unlocked: boolean;
  progress: number;
  target: number;
  missionId?: string;
}

export const WEATHER_OPTIONS: { value: Weather; icon: string; label: string }[] = [
  { value: "sunny", icon: "☀️", label: "Sunny" },
  { value: "partly-cloudy", icon: "🌤️", label: "Partly cloudy" },
  { value: "cloudy", icon: "☁️", label: "Cloudy" },
  { value: "rainy", icon: "🌧️", label: "Rainy" },
  { value: "thunderstorm", icon: "⛈️", label: "Thunderstorm" },
];

export const MOOD_OPTIONS: { value: Mood; icon: string; label: string }[] = [
  { value: "happy", icon: "😊", label: "Happy" },
  { value: "okay", icon: "😐", label: "Okay" },
  { value: "tired", icon: "😴", label: "Tired" },
  { value: "frustrated", icon: "😤", label: "Frustrated" },
  { value: "excited", icon: "🤩", label: "Excited" },
];

export const AVATAR_OPTIONS = ["🦁", "🐼", "🦊", "🐸", "🦄", "🐯", "🐨", "🐰", "🐶", "🐱"];

export const MISSION_ICONS = [
  "📖", "🀄", "🔢", "🔬", "🥋", "🎹", "⚽", "🎨", "🏃", "🎮",
  "📝", "🌍", "🎵", "🧪", "📚", "🏊", "🎯", "💻", "🧘", "⭐",
];

export const MISSION_COLORS = [
  "#4ECDC4", "#FF6B6B", "#A78BFA", "#51CF66", "#FFE66D",
  "#FF8FAB", "#74C0FC", "#FFA94D", "#69DB7C", "#DA77F2",
];
