import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DailyTickerRoot());
}

class DailyTickerRoot extends StatelessWidget {
  const DailyTickerRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const _AppWithWidgetSync(),
    );
  }
}

class _AppWithWidgetSync extends StatefulWidget {
  const _AppWithWidgetSync();

  @override
  State<_AppWithWidgetSync> createState() => _AppWithWidgetSyncState();
}

class _AppWithWidgetSyncState extends State<_AppWithWidgetSync>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppProvider>().syncFromWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Ticker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512),
          child: DailyTickerApp(),
        ),
      ),
    );
  }
}
