import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/types.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ProfilePicker extends StatefulWidget {
  const ProfilePicker({super.key});

  @override
  State<ProfilePicker> createState() => _ProfilePickerState();
}

class _ProfilePickerState extends State<ProfilePicker> {
  final _nameController = TextEditingController();
  var _avatar = avatarOptions.first;
  var _adding = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final data = provider.data;
    final activeProfile = provider.activeProfile;

    final showPicker = activeProfile == null ||
        provider.showProfilePicker ||
        data.profiles.isEmpty;

    if (!showPicker) return const SizedBox.shrink();

    final isAddingNew = _adding || data.profiles.isEmpty;

    return Material(
      color: const Color(0xFF581C87).withValues(alpha: 0.4),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFDE047), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isAddingNew ? 'Create your profile' : "Who's using the app?",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.purple700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAddingNew
                              ? 'Pick a name and avatar to get started!'
                              : 'Tap a profile to switch',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.purple500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!isAddingNew) ...[
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.82,
                            children: [
                              ...data.profiles.map((profile) {
                                final active = profile.id == activeProfile?.id;
                                return _ProfileTile(
                                  active: active,
                                  onTap: () => provider.switchProfile(profile.id),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        profile.avatar,
                                        style: const TextStyle(fontSize: 32, height: 1),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        profile.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.purple800,
                                          height: 1.1,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              _ProfileTile(
                                onTap: () => setState(() => _adding = true),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('➕', style: TextStyle(fontSize: 32, height: 1)),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add profile',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.purple800,
                                        height: 1.1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Your name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.purple700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _nameController,
                            maxLength: 12,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Alex',
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE9D5FF), width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE9D5FF), width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.purple400, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 5,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                            children: avatarOptions.map((a) {
                              final selected = _avatar == a;
                              return GestureDetector(
                                onTap: () => setState(() => _avatar = a),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFFEF9C3)
                                        : const Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: selected
                                        ? Border.all(color: const Color(0xFFFACC15), width: 2)
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(a, style: const TextStyle(fontSize: 24)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (data.profiles.isNotEmpty)
                                Expanded(
                                  child: OutlineButton(
                                    label: 'Back',
                                    expand: true,
                                    onPressed: () => setState(() => _adding = false),
                                  ),
                                ),
                              if (data.profiles.isNotEmpty) const SizedBox(width: 12),
                              Expanded(
                                child: CtaButton(
                                  label: "Let's go!",
                                  expand: true,
                                  enabled: _nameController.text.trim().isNotEmpty,
                                  onPressed: _nameController.text.trim().isEmpty
                                      ? null
                                      : () {
                                          provider.createProfile(
                                            _nameController.text,
                                            _avatar,
                                          );
                                          _nameController.clear();
                                          setState(() => _adding = false);
                                        },
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (!isAddingNew && data.profiles.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          OutlineButton(
                            label: 'Cancel',
                            expand: true,
                            onPressed: provider.closeProfilePicker,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.onTap,
    required this.child,
    this.active = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFEF9C3) : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? const Color(0xFFFACC15) : const Color(0xFFF3E8FF),
            width: 2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}
