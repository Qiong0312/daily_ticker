import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Uncaught async error: $error\n$stack');
        return true;
      };

      runApp(const DailyTickerRoot());
    },
    (error, stack) => debugPrint('Zone error: $error\n$stack'),
  );
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
    if (state != AppLifecycleState.resumed || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      if (!provider.ready) return;
      provider.syncFromWidget();
      provider.handleWidgetDeepLink();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Ticker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const _AppRoot(),
    );
  }
}

/// Fills the device on phone/tablet; keeps a phone-width column on Flutter web only.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  static const _webMaxWidth = 512.0;

  @override
  Widget build(BuildContext context) {
    final app = const DailyTickerApp();

    if (kIsWeb) {
      return Container(
        decoration: AppTheme.shellGradient,
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _webMaxWidth),
          child: app,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: AppTheme.shellGradient,
      child: app,
    );
  }
}
