import '../models/types.dart';

const defaultWeeklyGoal = 5;
const minWeeklyGoal = 1;
const maxWeeklyGoal = 7;

const defaultMissions = [
  (name: 'English', icon: '📖', color: '#4ECDC4', weeklyGoal: 5),
  (name: 'Chinese', icon: '🀄', color: '#FF6B6B', weeklyGoal: 5),
  (name: 'Maths', icon: '🔢', color: '#A78BFA', weeklyGoal: 5),
  (name: 'STS', icon: '🔬', color: '#51CF66', weeklyGoal: 3),
  (name: 'Taekwondo', icon: '🥋', color: '#FFE66D', weeklyGoal: 2),
  (name: 'Piano', icon: '🎹', color: '#FF8FAB', weeklyGoal: 7),
];

int getWeeklyGoal(Mission mission) {
  final goal = mission.weeklyGoal ?? defaultWeeklyGoal;
  return goal.clamp(minWeeklyGoal, maxWeeklyGoal);
}

Mission normalizeMission(Mission mission) {
  return mission.copyWith(weeklyGoal: getWeeklyGoal(mission));
}
