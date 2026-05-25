import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/types.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/missions_view.dart';
import 'screens/today_view.dart';
import 'screens/wins_view.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/profile_picker.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.activeProfile;
    if (profile == null) return const SizedBox.shrink();

    return Container(
      decoration: AppTheme.shellGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(profile.avatar, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hi there!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.purple600,
                            ),
                          ),
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.purple800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: provider.openProfilePicker,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.purple700,
                        backgroundColor: Colors.white.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE9D5FF)),
                        ),
                      ),
                      child: const Text(
                        'Switch',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: switch (provider.tab) {
                    AppTab.today => const TodayView(),
                    AppTab.wins => const WinsView(),
                    AppTab.missions => const MissionsView(),
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNav(
          activeTab: provider.tab,
          onTabChanged: provider.setTab,
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.loadingGradient,
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⭐', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text(
                'Daily Ticker',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purple800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DailyTickerApp extends StatelessWidget {
  const DailyTickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (!provider.ready) {
      return const LoadingScreen();
    }

    return Stack(
      children: [
        if (provider.activeProfile != null) const AppShell(),
        const ProfilePicker(),
      ],
    );
  }
}
