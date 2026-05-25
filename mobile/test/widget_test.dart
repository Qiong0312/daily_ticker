import 'package:flutter_test/flutter_test.dart';

import 'package:daily_ticker/main.dart';

void main() {
  testWidgets('App loads loading screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DailyTickerRoot());
    expect(find.text('Daily Ticker'), findsOneWidget);
  });
}
