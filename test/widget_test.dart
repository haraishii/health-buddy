import 'package:flutter_test/flutter_test.dart';
import 'package:health_buddy/data/dummy_data.dart';
import 'package:health_buddy/main.dart';

void main() {
  testWidgets('App opens on Home and can switch to Analytics', (tester) async {
    await tester.pumpWidget(const HealthBuddyApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Annida'), findsWidgets);

    await tester.tap(find.text('Analytics').last);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Health Score Trend'), findsOneWidget);
  });

  test('Dummy data matches the mockup', () {
    expect(DummyData.healthScore.latest, 85);
    expect(DummyData.healthScore.weekly.length, DummyData.weekDays.length);
    expect(DummyData.meals.fold<int>(0, (s, m) => s + m.kcal), 1420);
  });
}
