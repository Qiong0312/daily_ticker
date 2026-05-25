import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/types.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/color_utils.dart';
import '../utils/date_utils.dart';
import '../utils/stats.dart';

class TodayView extends StatefulWidget {
  const TodayView({super.key});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  var _justCompletedAll = false;
  var _wasAllDone = false;
  Timer? _celebrateTimer;

  @override
  void dispose() {
    _celebrateTimer?.cancel();
    super.dispose();
  }

  void _checkCelebration(bool allDone) {
    if (allDone && !_wasAllDone) {
      setState(() => _justCompletedAll = true);
      _celebrateTimer?.cancel();
      _celebrateTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _justCompletedAll = false);
      });
      _wasAllDone = true;
    } else if (!allDone) {
      _wasAllDone = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.activeProfile!;
    final profileId = profile.id;
    final missions = provider.getMissionsForProfile(profileId);
    final dateKey = todayKey();
    final entry = provider.getTodayEntry();
    final selectedIds = provider.getTodaySelectedMissions();
    final streak = getStreak(provider.data.dailyMissions, profileId);

    final todayMissions = provider.data.dailyMissions
        .where((dm) => dm.profileId == profileId && dm.date == dateKey)
        .map((dm) {
          try {
            final mission = missions.firstWhere((m) => m.id == dm.missionId);
            return (dm: dm, mission: mission);
          } catch (_) {
            return null;
          }
        })
        .whereType<({DailyMission dm, Mission mission})>()
        .toList();

    final completedCount = todayMissions.where((t) => t.dm.completed).length;
    final totalCount = todayMissions.length;
    final allDone = totalCount > 0 && completedCount == totalCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCelebration(allDone);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          borderColor: const Color(0xFF7DD3FC),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "How's today?",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.sky600,
                          ),
                        ),
                        Text(
                          formatDisplayDate(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.purple800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '🔥 $streak-day streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _OptionGroup(
                    label: 'Weather',
                    children: weatherOptions.map((w) {
                      final selected = entry?.weather == w.value;
                      return _EmojiButton(
                        emoji: w.icon,
                        selected: selected,
                        onTap: () => provider.setWeather(w.value),
                      );
                    }).toList(),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _OptionGroup(
                    label: 'Feel',
                    children: moodOptions.map((m) {
                      final selected = entry?.mood == m.value;
                      return _EmojiButton(
                        emoji: m.icon,
                        selected: selected,
                        onTap: () => provider.setMood(m.value),
                      );
                    }).toList(),
                  )),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          borderColor: AppColors.purple400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pick your missions!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purple800,
                ),
              ),
              const SizedBox(height: 12),
              if (missions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'No missions yet!',
                        style: TextStyle(color: AppColors.purple600),
                      ),
                      TextButton(
                        onPressed: () => provider.setTab(AppTab.missions),
                        child: const Text(
                          'Go to My Missions',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.purple700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: missions.map((mission) {
                    final selected = selectedIds.contains(mission.id);
                    return GestureDetector(
                      onTap: () => provider.toggleMissionOnToday(mission.id),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: selected ? 0.5 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: parseHexColor(mission.color),
                            borderRadius: BorderRadius.circular(999),
                            border: selected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${mission.icon} ${mission.name}${selected ? ' ⭐' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          borderColor: const Color(0xFFFACC15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's list",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple800,
                    ),
                  ),
                  if (totalCount > 0)
                    Text(
                      '$completedCount/$totalCount ⭐',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple600,
                      ),
                    ),
                ],
              ),
              if (allDone) ...[
                const SizedBox(height: 12),
                AnimatedScale(
                  scale: _justCompletedAll ? 1.05 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFDE047), Color(0xFFF472B6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Super day! You earned all your stars! 🎉',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
              if (totalCount > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: completedCount / totalCount,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFF3E8FF),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFB923C)),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (todayMissions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tap a mission above to add it here!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.purple600),
                  ),
                )
              else
                ...todayMissions.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TodayMissionRow(
                        mission: item.mission,
                        completed: item.dm.completed,
                        onToggle: () =>
                            provider.toggleMissionComplete(item.mission.id),
                        onRemove: () =>
                            provider.removeFromToday(item.mission.id),
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.purple500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(spacing: 4, runSpacing: 4, children: children),
      ],
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFEF9C3) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: const Color(0xFFFACC15), width: 2)
              : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _TodayMissionRow extends StatelessWidget {
  const _TodayMissionRow({
    required this.mission,
    required this.completed,
    required this.onToggle,
    required this.onRemove,
  });

  final Mission mission;
  final bool completed;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(mission.color);

    return Container(
      decoration: BoxDecoration(
        color: missionTint(mission.color, completed ? 22 : 38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? const Color(0xFFFCD34D).withValues(alpha: 0.8) : Colors.transparent,
          width: 2,
        ),
        boxShadow: completed
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                ),
              ],
      ),
      child: Row(
        children: [
          Container(width: 6, height: 72, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: completed
                              ? Border.all(color: const Color(0xFFFCD34D), width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(mission.icon, style: const TextStyle(fontSize: 20)),
                      ),
                      if (completed)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFBBF24),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.purple900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (completed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Star earned! ✨',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          )
                        else
                          const Text(
                            'Tap the star when done',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: completed
                            ? const Color(0xFFFEF3C7)
                            : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: completed
                            ? Border.all(color: const Color(0xFFFCD34D), width: 2)
                            : Border.all(
                                color: missionTint(mission.color, 55),
                                width: 2,
                              ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        completed ? '⭐' : '☆',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close, color: AppColors.purple400, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}