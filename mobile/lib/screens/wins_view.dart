import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/backup.dart';
import '../models/types.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/achievements.dart';
import '../utils/color_utils.dart';
import '../utils/date_utils.dart';
import '../utils/stats.dart';

class WinsView extends StatefulWidget {
  const WinsView({super.key});

  @override
  State<WinsView> createState() => _WinsViewState();
}

class _WinsViewState extends State<WinsView> {
  Period _period = Period.week;
  String? _selectedDay;
  late DateTime _calendarMonth;

  @override
  void initState() {
    super.initState();
    _calendarMonth = startOfMonth(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.activeProfile!;
    final profileId = profile.id;
    final missions = provider.getMissionsForProfile(profileId);
    final now = DateTime.now();

    final displayMonth = _period == Period.year ? _calendarMonth : startOfMonth(now);
    final calendarYear = displayMonth.year;
    final calendarMonthIndex = displayMonth.month - 1;

    final daysInMonth = getDaysInMonth(calendarYear, calendarMonthIndex);
    final firstDay = DateTime(calendarYear, calendarMonthIndex + 1, 1).weekday;
    final offset = firstDay == DateTime.sunday ? 6 : firstDay - 1;

    final earliestMonth = getEarliestActivityMonth(
      provider.data.dailyMissions,
      provider.data.dailyEntries,
      profileId,
      DateTime.parse(profile.createdAt),
    );
    final currentMonth = startOfMonth(now);
    final canGoPrev = _period == Period.year &&
        displayMonth.isAfter(DateTime(earliestMonth.year, earliestMonth.month));
    final canGoNext = _period == Period.year &&
        displayMonth.isBefore(DateTime(currentMonth.year, currentMonth.month));

    final stars = countStars(provider.data.dailyMissions, profileId, _period);
    final topMissions = getTopMissions(
      provider.data.dailyMissions,
      missions,
      profileId,
      _period,
    );
    final topMission = topMissions.isEmpty ? null : topMissions.first.mission;
    final achievements = computeAchievements(
      provider.data.dailyMissions,
      missions,
      profileId,
    );
    final achievementGroups = groupAchievementsByCategory(achievements);
    final weeklyGoalMedals = computeWeeklyGoalLifetimeMedals(
      provider.data.dailyMissions,
      missions,
      profileId,
    );
    final activeDays = getActiveDaysInMonth(
      provider.data.dailyMissions,
      profileId,
      calendarYear,
      calendarMonthIndex,
    );
    final maxCount = topMissions.isEmpty ? 1 : topMissions.first.count;

    final periodLabel = switch (_period) {
      Period.week => 'this week',
      Period.month => 'this month',
      Period.year => 'this year',
    };

    DailyEntry? recapEntry;
    if (_selectedDay != null) {
      try {
        recapEntry = provider.data.dailyEntries.firstWhere(
          (e) => e.profileId == profileId && e.date == _selectedDay,
        );
      } catch (_) {
        recapEntry = null;
      }
    }

    final recapMissions = _selectedDay != null
        ? getDayRecap(
            provider.data.dailyMissions,
            missions,
            profileId,
            _selectedDay!,
          )
        : <Mission>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _PeriodButton(
              label: 'This week',
              selected: _period == Period.week,
              onTap: () => setState(() {
                _period = Period.week;
                _selectedDay = null;
              }),
            ),
            const SizedBox(width: 8),
            _PeriodButton(
              label: 'This month',
              selected: _period == Period.month,
              onTap: () => setState(() {
                _period = Period.month;
                _calendarMonth = startOfMonth(DateTime.now());
                _selectedDay = null;
              }),
            ),
            const SizedBox(width: 8),
            _PeriodButton(
              label: 'This year',
              selected: _period == Period.year,
              onTap: () => setState(() {
                _period = Period.year;
                _selectedDay = null;
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          borderColor: const Color(0xFFFACC15),
          child: Column(
            children: [
              Text(
                periodLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple600,
                ),
              ),
              Text(
                '$stars ⭐',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purple800,
                ),
              ),
              if (topMission != null)
                Text.rich(
                  TextSpan(
                    style: const TextStyle(color: AppColors.purple600),
                    children: [
                      const TextSpan(text: 'Your #1 mission: '),
                      TextSpan(
                        text: '${topMission.icon} ${topMission.name}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
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
                'What you did most!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purple800,
                ),
              ),
              const SizedBox(height: 16),
              if (topMissions.isEmpty)
                const Text(
                  'Complete missions to see your stats here!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.purple500),
                )
              else
                ...topMissions.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.mission.icon} ${item.mission.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.purple800,
                                ),
                              ),
                              Text(
                                '${item.count} ⭐',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.purple600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: item.count / maxCount,
                              minHeight: 16,
                              backgroundColor: const Color(0xFFF3E8FF),
                              valueColor: AlwaysStoppedAnimation(
                                parseHexColor(item.mission.color),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
        if (_period == Period.month || _period == Period.year) ...[
          const SizedBox(height: 16),
          AppCard(
            borderColor: const Color(0xFF7DD3FC),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_period == Period.year)
                      _CalendarNavButton(
                        enabled: canGoPrev,
                        icon: Icons.chevron_left,
                        onTap: () => setState(() {
                          _calendarMonth = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month - 1,
                          );
                          _selectedDay = null;
                        }),
                      )
                    else
                      const SizedBox(width: 36),
                    Expanded(
                      child: Text(
                        formatMonthYear(displayMonth),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple800,
                        ),
                      ),
                    ),
                    if (_period == Period.year)
                      _CalendarNavButton(
                        enabled: canGoNext,
                        icon: Icons.chevron_right,
                        onTap: () => setState(() {
                          _calendarMonth = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month + 1,
                          );
                          _selectedDay = null;
                        }),
                      )
                    else
                      const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                      .map((d) => Expanded(
                            child: Text(
                              d,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.purple500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: offset + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < offset) return const SizedBox.shrink();
                    final day = index - offset + 1;
                    final dateKey = formatDateKey(
                      DateTime(calendarYear, calendarMonthIndex + 1, day),
                    );
                    final hasStar = activeDays.contains(day);
                    final selected = _selectedDay == dateKey;

                    return GestureDetector(
                      onTap: hasStar
                          ? () => setState(() => _selectedDay = dateKey)
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasStar
                              ? const Color(0xFFFEF9C3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(color: AppColors.purple600, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          hasStar ? '⭐' : '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: hasStar
                                ? AppColors.purple800
                                : AppColors.purple400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        if (_selectedDay != null) ...[
          const SizedBox(height: 16),
          AppCard(
            borderColor: const Color(0xFFF9A8D4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatDayRecapDate(_selectedDay!),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedDay = null),
                      icon: const Icon(Icons.close, color: AppColors.purple400),
                    ),
                  ],
                ),
                if (recapEntry?.weather != null)
                  Text(
                    'Weather: ${weatherOptions.firstWhere((w) => w.value == recapEntry!.weather).icon}',
                    style: const TextStyle(color: AppColors.purple600),
                  ),
                if (recapEntry?.mood != null)
                  Text(
                    'Mood: ${moodOptions.firstWhere((m) => m.value == recapEntry!.mood).icon}',
                    style: const TextStyle(color: AppColors.purple600),
                  ),
                if (recapMissions.isEmpty)
                  const Text(
                    'No completed missions this day.',
                    style: TextStyle(color: AppColors.purple500),
                  )
                else
                  ...recapMissions.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '⭐ ${m.icon} ${m.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        ...AchievementCategory.values.map((category) {
          final items = sortAchievementsForDisplay(
            achievementGroups[category]!,
            category: category,
          );
          if (items.isEmpty) return const SizedBox.shrink();
          final label = achievementCategoryLabels[category]!;

          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AppCard(
              borderColor: const Color(0xFFFDBA74),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${label.icon} ${label.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievementCategorySubtitle(category, formatWeekRange()),
                    style: const TextStyle(fontSize: 12, color: AppColors.purple500),
                  ),
                  if (category == AchievementCategory.subject) ...[
                    const SizedBox(height: 10),
                    _WeeklyGoalMedalTotals(counts: weeklyGoalMedals),
                  ],
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isTwoCol = category == AchievementCategory.subject;
                      const spacing = 8.0;
                      final cols = isTwoCol ? 2 : 1;
                      final itemWidth =
                          (constraints.maxWidth - spacing * (cols - 1)) / cols;

                      if (isTwoCol) {
                        return _AlignedAchievementGrid(
                          items: items,
                          spacing: 10,
                        );
                      }

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final a in items)
                            SizedBox(
                              width: itemWidth,
                              child: _AchievementCard(achievement: a),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        const _ProgressBackupSection(),
      ],
    );
  }
}

class _AlignedAchievementGrid extends StatelessWidget {
  const _AlignedAchievementGrid({
    required this.items,
    required this.spacing,
  });

  final List<Achievement> items;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < items.length ? spacing : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _AchievementCard(achievement: left, stretch: true),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: right != null
                      ? _AchievementCard(achievement: right, stretch: true)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

BoxDecoration _medalTierChipDecoration(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.diamond:
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA), Color(0xFF4DD0E1)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF26C6DA), width: 1.5),
      );
    case AchievementTier.bronze:
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8E4C8), Color(0xFFCD9B5A), Color(0xFF7A4A22)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF6B3F1A), width: 1.5),
      );
    case AchievementTier.silver:
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F2FE), Color(0xFFF1F5F9), Color(0xFFBAE6FD)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF94A3B8), width: 1.5),
      );
    case AchievementTier.gold:
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEFCE8), Color(0xFFFEF08A), Color(0xFFFBBF24)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFF59E0B), width: 1.5),
      );
    case AchievementTier.locked:
      return BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      );
  }
}

class _WeeklyGoalMedalTotals extends StatelessWidget {
  const _WeeklyGoalMedalTotals({required this.counts});

  final WeeklyGoalMedalCounts counts;

  @override
  Widget build(BuildContext context) {
    const items = [
      (tier: AchievementTier.bronze, label: 'Bronze', emoji: '🥉'),
      (tier: AchievementTier.silver, label: 'Silver', emoji: '🥈'),
      (tier: AchievementTier.gold, label: 'Gold', emoji: '🥇'),
      (tier: AchievementTier.diamond, label: 'Diamond', emoji: '💎'),
    ];

    int countFor(AchievementTier tier) => switch (tier) {
          AchievementTier.bronze => counts.bronze,
          AchievementTier.silver => counts.silver,
          AchievementTier.gold => counts.gold,
          AchievementTier.diamond => counts.diamond,
          _ => 0,
        };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALL-TIME MEDALS COLLECTED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.purple500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _MedalCountChip(
                    tier: items[i].tier,
                    label: items[i].label,
                    emoji: items[i].emoji,
                    count: countFor(items[i].tier),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MedalCountChip extends StatelessWidget {
  const _MedalCountChip({
    required this.tier,
    required this.label,
    required this.emoji,
    required this.count,
  });

  final AchievementTier tier;
  final String label;
  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: _medalTierChipDecoration(tier),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.purple900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBackupSection extends StatefulWidget {
  const _ProgressBackupSection();

  @override
  State<_ProgressBackupSection> createState() => _ProgressBackupSectionState();
}

class _ProgressBackupSectionState extends State<_ProgressBackupSection> {
  final _sectionKey = GlobalKey();
  var _busy = false;

  Rect get _shareOrigin =>
      shareOriginFromContext(_sectionKey.currentContext ?? context);

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
      ),
    );
  }

  Future<void> _run(Future<void> Function() action, String successMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _showMessage(successMessage);
    } on BackupCancelled {
      // User dismissed the file picker — no message.
    } catch (e) {
      if (mounted) _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This replaces all profiles, missions, and history on this device '
          'with the backup file. Save a new backup first if you are unsure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Restore',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.purple700,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return AppCard(
      key: _sectionKey,
      borderColor: const Color(0xFF86EFAC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💾 Save your progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.purple800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Progress saves automatically. Export or import a JSON backup to '
            'restore after a crash or reinstall.',
            style: TextStyle(fontSize: 13, color: AppColors.purple600, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BackupFileButton(
                  label: 'Export backup file',
                  enabled: !_busy,
                  onPressed: _busy
                      ? null
                      : () {
                          final origin = _shareOrigin;
                          _run(
                            () => provider.exportProgressBackupFile(origin),
                            'Backup ready — choose where to save the file.',
                          );
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BackupFileButton(
                  label: 'Import backup file',
                  enabled: !_busy,
                  onPressed: _busy
                      ? null
                      : () async {
                          if (_busy) return;
                          setState(() => _busy = true);
                          try {
                            final imported = await importProgressBackup();
                            if (!mounted) return;
                            final confirmed = await _confirmRestore();
                            if (!confirmed || !mounted) return;
                            await provider.restoreProgressFromBackup(imported);
                            if (mounted) {
                              _showMessage('Progress restored from backup.');
                            }
                          } on BackupCancelled {
                            // No message.
                          } catch (e) {
                            if (mounted) {
                              _showMessage(e.toString(), isError: true);
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                ),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackupFileButton extends StatelessWidget {
  const _BackupFileButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.purple600,
        side: const BorderSide(color: Color(0xFFE9D5FF), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFDE047) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.purple800 : AppColors.purple600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({
    required this.enabled,
    required this.icon,
    required this.onTap,
  });

  final bool enabled;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: enabled ? const Color(0xFFF3E8FF) : const Color(0xFFF3E8FF).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Icon(icon, color: AppColors.purple700),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    this.stretch = false,
  });

  final Achievement achievement;
  final bool stretch;

  static const _progressBlockHeight = 13.0; // gap + 5px bar

  @override
  Widget build(BuildContext context) {
    final tier = achievement.tier;
    final unlocked = achievement.unlocked;
    final growthStyle = achievement.growthStyle;
    final isMaster = achievement.progress >= achievement.target;
    final progressPct = achievement.target > 0
        ? (achievement.progress / achievement.target).clamp(0.0, 1.0)
        : 0.0;
    final hideProgressBar = growthStyle
        ? !isMaster
        : tier == AchievementTier.gold;

    final decoration =
        growthStyle ? _neutralAchievementDecoration() : _tierDecoration(tier, unlocked);
    final descTop = stretch ? 5.0 : 0.0;
    final hintTop = stretch ? 5.0 : 2.0;
    final badgeTop = stretch ? 6.0 : 2.0;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 22,
                height: stretch ? 1.2 : 1.1,
                color: unlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 13,
                      height: stretch ? 1.35 : 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple900,
                    ),
                  ),
                  ...achievement.description.split('\n').asMap().entries.map((entry) {
                    final isHint = entry.key > 0;
                    return Padding(
                      padding: EdgeInsets.only(top: isHint ? hintTop : descTop),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: isHint ? 9 : 10,
                          height: stretch ? 1.35 : 1.25,
                          color: isHint ? AppColors.purple500 : AppColors.purple700,
                          fontWeight: isHint ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    );
                  }),
                  if (!growthStyle && unlocked)
                    Padding(
                      padding: EdgeInsets.only(top: badgeTop),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tier == AchievementTier.diamond
                              ? '💎 Diamond bonus!'
                              : '${tier.name} unlocked',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    )
                  else if (!growthStyle && !unlocked)
                    Padding(
                      padding: EdgeInsets.only(top: badgeTop),
                      child: const Text(
                        'Keep going!',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (stretch) const Spacer(),
        if (!hideProgressBar)
          Padding(
            padding: EdgeInsets.only(top: stretch ? 8 : 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progressPct,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFEC4899)),
              ),
            ),
          )
        else if (stretch)
          const SizedBox(height: _progressBlockHeight),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: stretch ? 10 : 8,
      ),
      decoration: decoration,
      child: content,
    );
  }

  BoxDecoration _neutralAchievementDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Color(0xFFE5E7EB), width: 2),
    );
  }

  BoxDecoration _tierDecoration(AchievementTier tier, bool unlocked) {
    if (!unlocked) {
      return _neutralAchievementDecoration();
    }

    switch (tier) {
      case AchievementTier.diamond:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA), Color(0xFF4DD0E1)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF26C6DA), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4DD0E1).withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        );
      case AchievementTier.bronze:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8E4C8), Color(0xFFCD9B5A), Color(0xFF7A4A22)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6B3F1A), width: 2),
        );
      case AchievementTier.silver:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F2FE), Color(0xFFF1F5F9), Color(0xFFBAE6FD)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF94A3B8), width: 2),
        );
      case AchievementTier.gold:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEFCE8), Color(0xFFFEF08A), Color(0xFFFBBF24)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        );
      case AchievementTier.locked:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        );
    }
  }
}
