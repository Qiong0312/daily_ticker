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

export function startOfWeek(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

export function startOfMonth(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

export function startOfYear(date: Date): Date {
  return new Date(date.getFullYear(), 0, 1);
}

export function isDateInRange(dateKey: string, start: Date, end: Date): boolean {
  const d = parseDateKey(dateKey);
  return d >= start && d <= end;
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
