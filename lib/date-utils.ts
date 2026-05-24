export function todayKey(): string {
  return formatDateKey(new Date());
}

export function formatDateKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export function formatDisplayDate(date: Date): string {
  return date.toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  });
}

/** Weeks run Monday 00:00 through Sunday (calendar week, Mon start). */
export const WEEK_STARTS_ON = 1; // Monday (Date.getDay() index)

export function startOfWeek(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  // Sunday (0) -> go back 6 days to Monday; otherwise back to this week's Monday.
  const diff = day === 0 ? -6 : WEEK_STARTS_ON - day;
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

export function endOfWeek(date: Date): Date {
  const end = startOfWeek(date);
  end.setDate(end.getDate() + 6);
  end.setHours(23, 59, 59, 999);
  return end;
}

export function formatWeekRange(ref: Date = new Date()): string {
  const start = startOfWeek(ref);
  const end = endOfWeek(ref);

  if (start.getMonth() === end.getMonth()) {
    const month = start.toLocaleDateString("en-US", { month: "short" });
    return `${month} ${start.getDate()}–${end.getDate()}`;
  }

  const startLabel = start.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
  const endLabel = end.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
  return `${startLabel} – ${endLabel}`;
}

export function startOfMonth(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

export function startOfYear(date: Date): Date {
  return new Date(date.getFullYear(), 0, 1);
}

export function isDateInRange(dateKey: string, start: Date, end: Date): boolean {
  // Compare YYYY-MM-DD strings so week/month boundaries stay exact (Mon reset).
  const startKey = formatDateKey(start);
  const endKey = formatDateKey(end);
  return dateKey >= startKey && dateKey <= endKey;
}

export function parseDateKey(key: string): Date {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d);
}

export function getPeriodRange(period: "week" | "month" | "year", ref: Date = new Date()) {
  const end = new Date(ref);
  end.setHours(23, 59, 59, 999);

  if (period === "week") {
    return { start: startOfWeek(ref), end };
  }
  if (period === "month") {
    return { start: startOfMonth(ref), end };
  }
  return { start: startOfYear(ref), end };
}

export function getDaysInMonth(year: number, month: number): number {
  return new Date(year, month + 1, 0).getDate();
}
