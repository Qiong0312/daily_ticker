export function missionTint(color: string, amount: number): string {
  return `color-mix(in srgb, ${color} ${amount}%, white)`;
}
