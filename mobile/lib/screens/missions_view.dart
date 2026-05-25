import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/defaults.dart';
import '../models/types.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/color_utils.dart';

class MissionsView extends StatefulWidget {
  const MissionsView({super.key});

  @override
  State<MissionsView> createState() => _MissionsViewState();
}

class _MissionsViewState extends State<MissionsView> {
  Future<void> _openForm({Mission? mission}) async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xFF581C87).withValues(alpha: 0.3),
      builder: (ctx) => _MissionForm(
        mission: mission,
        onSave: (data) {
          final provider = context.read<AppProvider>();
          if (mission != null) {
            provider.updateMission(
              mission.id,
              name: data.name,
              icon: data.icon,
              color: data.color,
              weeklyGoal: data.weeklyGoal,
            );
          } else {
            provider.addMission(
              name: data.name,
              icon: data.icon,
              color: data.color,
              weeklyGoal: data.weeklyGoal,
            );
          }
          Navigator.pop(ctx);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _confirmDelete(Mission mission) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${mission.name}?'),
        content: const Text(
          'Remove this mission from your list? Your old stars stay in My Wins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      context.read<AppProvider>().deleteMission(mission.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.activeProfile!;
    final missions = provider.getMissionsForProfile(profile.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Missions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple800,
                  ),
                ),
                CtaButton(
                  label: '+ Add',
                  onPressed: () => _openForm(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Create and edit your mission bubbles. Set a weekly star goal for each one!',
              style: TextStyle(fontSize: 14, color: AppColors.purple600),
            ),
            const SizedBox(height: 16),
            if (missions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No missions yet — tap Add to create your first one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.purple600),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: missions.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final ids = missions.map((m) => m.id).toList();
                  final id = ids.removeAt(oldIndex);
                  ids.insert(newIndex, id);
                  provider.reorderMissions(ids);
                },
                itemBuilder: (context, index) {
                  final mission = missions[index];
                  return _MissionListItem(
                    key: ValueKey(mission.id),
                    index: index,
                    mission: mission,
                    onEdit: () => _openForm(mission: mission),
                    onDelete: () => _confirmDelete(mission),
                  );
                },
              ),
      ],
    );
  }
}

class _MissionListItem extends StatelessWidget {
  const _MissionListItem({
    super.key,
    required this.index,
    required this.mission,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final Mission mission;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3E8FF), width: 2),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle, color: AppColors.purple400),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: parseHexColor(mission.color),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(mission.icon, style: const TextStyle(fontSize: 20)),
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
                    color: AppColors.purple800,
                  ),
                ),
                Text(
                  '${getWeeklyGoal(mission)}⭐ weekly goal · resets Monday',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF3E8FF),
              foregroundColor: AppColors.purple700,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _MissionFormData {
  const _MissionFormData({
    required this.name,
    required this.icon,
    required this.color,
    required this.weeklyGoal,
  });

  final String name;
  final String icon;
  final String color;
  final int weeklyGoal;
}

class _MissionForm extends StatefulWidget {
  const _MissionForm({
    required this.mission,
    required this.onSave,
    required this.onCancel,
  });

  final Mission? mission;
  final ValueChanged<_MissionFormData> onSave;
  final VoidCallback onCancel;

  @override
  State<_MissionForm> createState() => _MissionFormState();
}

class _MissionFormState extends State<_MissionForm> {
  late final TextEditingController _nameController;
  late String _icon;
  late String _color;
  late int _weeklyGoal;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.mission?.name ?? '');
    _icon = widget.mission?.icon ?? missionIcons.first;
    _color = widget.mission?.color ?? missionColors.first;
    _weeklyGoal = widget.mission != null
        ? getWeeklyGoal(widget.mission!)
        : defaultWeeklyGoal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF581C87).withValues(alpha: 0.3),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFDE047), width: 4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.mission != null ? 'Edit mission' : 'New mission',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple800,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple700,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _nameController,
                  maxLength: 20,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE9D5FF), width: 2),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Icon',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple700,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 140,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: missionIcons.length,
                    itemBuilder: (context, index) {
                      final icon = missionIcons[index];
                      final selected = _icon == icon;
                      return GestureDetector(
                        onTap: () => setState(() => _icon = icon),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFFEF9C3) : null,
                            borderRadius: BorderRadius.circular(8),
                            border: selected
                                ? Border.all(color: const Color(0xFFFACC15), width: 2)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Color',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: missionColors.map((c) {
                    final selected = _color == c;
                    return GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: parseHexColor(c),
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: AppColors.purple700, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Weekly star goal',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple700,
                  ),
                ),
                const Text(
                  'How many stars to aim for each week? Counts reset every Monday.',
                  style: TextStyle(fontSize: 12, color: AppColors.purple500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(maxWeeklyGoal - minWeeklyGoal + 1, (i) {
                    final n = i + minWeeklyGoal;
                    final selected = _weeklyGoal == n;
                    return GestureDetector(
                      onTap: () => setState(() => _weeklyGoal = n),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFFEF9C3) : const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(12),
                          border: selected
                              ? Border.all(color: const Color(0xFFFACC15), width: 2)
                              : null,
                        ),
                        child: Text(
                          '$n⭐',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selected ? AppColors.purple800 : AppColors.purple600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlineButton(
                        label: 'Cancel',
                        expand: true,
                        onPressed: widget.onCancel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CtaButton(
                        label: 'Save mission',
                        expand: true,
                        enabled: _nameController.text.trim().isNotEmpty,
                        onPressed: _nameController.text.trim().isEmpty
                            ? null
                            : () => widget.onSave(_MissionFormData(
                                  name: _nameController.text.trim(),
                                  icon: _icon,
                                  color: _color,
                                  weeklyGoal: _weeklyGoal,
                                )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
