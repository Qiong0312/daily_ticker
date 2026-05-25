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
      child: MaterialApp(
        title: 'Daily Ticker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 512),
            child: DailyTickerApp(),
          ),
        ),
      ),
    );
  }
}
