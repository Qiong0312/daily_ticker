import 'package:flutter/material.dart';

import '../models/types.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onTabChanged;

  static const tabs = [
    (tab: AppTab.today, label: 'Today'),
    (tab: AppTab.wins, label: 'My Wins'),
    (tab: AppTab.missions, label: 'Missions'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: const Color(0xFFF3E8FF).withValues(alpha: 0.8), width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tabs.map((t) {
            final active = activeTab == t.tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(t.tab),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFFF3E8FF),
                          width: 2,
                        ),
                        gradient: active
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFEF9C3),
                                  Color(0xFFFEF3C7),
                                  Color(0xFFFCE7F3),
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFF0F9FF),
                                  Color(0xFFF5F3FF),
                                  Color(0xFFFDF2F8),
                                ],
                              ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _NavIcon(tab: t.tab, active: active),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.purple800 : AppColors.purple500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.tab, required this.active});

  final AppTab tab;
  final bool active;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case AppTab.today:
        return Icon(Icons.home_rounded, color: active ? Colors.amber.shade700 : AppColors.purple500, size: 22);
      case AppTab.wins:
        return Icon(Icons.star_rounded, color: active ? Colors.amber.shade700 : AppColors.purple500, size: 22);
      case AppTab.missions:
        return Icon(Icons.track_changes_rounded, color: active ? Colors.amber.shade700 : AppColors.purple500, size: 22);
    }
  }
}
