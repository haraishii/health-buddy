import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_buddy/app/health_buddy_app.dart';
import 'package:health_buddy/data/api/api_client.dart';
import 'package:health_buddy/data/api/api_models.dart';
import 'package:health_buddy/data/api/session.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _user = {
  'id': 1,
  'email': 'annida@example.com',
  'name': 'Annida',
  'status': 'Student',
  'life_stage': 'general',
  'birth_date': '2006-03-14',
  'age': 20,
  'sex': 'F',
  'height_cm': 158,
  'weight_kg': 52,
  'created_at': '2026-05-01T08:00:00Z',
};

final _healthScore = {
  'latest': 81,
  'latest_date': '2026-10-14',
  'average': 78,
  'change_percent': 12,
  'balance': {'nutrition': 70, 'sleep': 80, 'stress': 60, 'exercise': 55},
};

Map<String, dynamic> _day(String date) => {
  'date': date,
  'calories_in': 1500,
  'protein_g': 42,
  'carbs_g': 200,
  'fat_g': 40,
  'fiber_g': 12,
  'sugar_g': 20,
  'sodium_mg': 1500,
  'water_ml': 1250,
  'steps': 6240,
  'sleep_hours': 6.5,
  'stress_avg': 4,
  'exercise_minutes': 20,
  'calories_burned': 120,
};

/// A fake backend with just enough data for the screens in these tests.
http.Client _fakeBackend() => MockClient((request) async {
  final path = request.url.path;
  final Object body = switch (path) {
    '/api/v1/me/summary' => {
      'date': '2026-10-14',
      'user': _user,
      'totals': _day('2026-10-14'),
      'goals': [
        {'key': 'steps', 'current': 6240, 'target': 8000, 'unit': 'steps'},
        {'key': 'water', 'current': 1250, 'target': 2350, 'unit': 'ml'},
        {'key': 'protein', 'current': 42, 'target': 60, 'unit': 'g'},
        {'key': 'sleep_last_night', 'current': 6.5, 'target': 7, 'unit': 'h'},
      ],
      'targets': null,
      'targets_error': null,
      'latest_stress': null,
      'stress_level': 'Low',
      'activity_level': 'Moderate',
      'health_score': _healthScore,
      'week_averages': {'exercise_days': 3},
      'tip': {'id': 'TP001', 'topic': 'sleep', 'text': 'Try going to bed 30 minutes earlier tonight.'},
    },
    '/api/v1/me/analytics' => {
      'from': '2026-10-12',
      'to': '2026-10-18',
      'days': [for (var d = 12; d <= 18; d++) _day('2026-10-$d')],
      'scores': [
        for (var d = 12; d <= 18; d++) {'date': '2026-10-$d', 'score': 70 + d},
      ],
      'health_score': _healthScore,
      'averages': {'stress': 4.2, 'steps': 7000, 'exercise_days': 4, 'calories_burned': 300},
      'previous_averages': <String, dynamic>{},
      'nutrition_percent': {'protein': 70, 'carbs': 60, 'fat': 80, 'fiber': 40},
      'vs_previous': {'stress_change_percent': -15, 'exercise_change_percent': 18, 'healthy_meals_change_pct': 22},
      'insights': <String, dynamic>{},
      'healthy_meals': 5,
      'healthy_meals_sentence': '5 healthy meals logged this week.',
      'insight_sentences': ['Your stress drops 20% on days you exercise.'],
      'recommendation': 'Walk 20 minutes after class.',
      'tips': <Object>[],
    },
    _ => {'error': 'not found'},
  };
  final status = body is Map && body.containsKey('error') ? 404 : 200;
  return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
});

/// Pumps enough frames for a tab switch, the API response and the crossfade to finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}

/// A session that is already signed in, talking to the fake backend instead of the network.
Future<Session> signedInSession() async {
  final session = Session(
    store: MemorySessionStore({'auth_token': 'test-token', 'auth_user': jsonEncode(_user)}),
    client: ApiClient(baseUrl: 'http://test', httpClient: _fakeBackend()),
  );
  await session.restore();
  return session;
}

void main() {
  testWidgets('Home shows data from the API, and Analytics opens', (tester) async {
    await tester.pumpWidget(HealthBuddyApp(session: await signedInSession()));
    await settle(tester);
    expect(find.text('Annida'), findsWidgets);
    expect(find.text('Try going to bed 30 minutes earlier tonight.'), findsOneWidget);
    expect(find.textContaining('Moderate', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Analytics').last);
    await settle(tester);
    expect(find.text('Health Score Trend'), findsOneWidget);
    expect(find.text('Your stress drops 20% on days you exercise.'), findsOneWidget);
  });

  testWidgets('Signed out users see the login screen, and log out returns there', (tester) async {
    final session = Session(store: MemorySessionStore());
    await session.restore();
    await tester.pumpWidget(HealthBuddyApp(session: session));
    await settle(tester);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.textContaining('Create an account', findRichText: true), findsOneWidget);

    await tester.pumpWidget(HealthBuddyApp(session: await signedInSession()));
    await settle(tester);
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    await tester.ensureVisible(find.text('Log out'));
    await tester.tap(find.text('Log out'));
    await settle(tester);
    expect(find.textContaining('Create an account', findRichText: true), findsOneWidget);
  });

  test('API models parse the backend JSON', () {
    final a = Analytics.fromJson(
      (jsonDecode(
        jsonEncode({
          'from': '2026-10-12',
          'to': '2026-10-12',
          'days': [_day('2026-10-12')],
          'scores': [
            {'date': '2026-10-12', 'score': null},
          ],
          'health_score': _healthScore,
          'averages': {'stress': 4.2},
          'previous_averages': <String, dynamic>{},
          'nutrition_percent': null,
          'vs_previous': {'stress_change_percent': null},
          'insights': <String, dynamic>{},
          'healthy_meals': 0,
          'healthy_meals_sentence': '0 healthy meals logged this week.',
          'insight_sentences': <Object>[],
          'recommendation': null,
          'tips': <Object>[],
        }),
      ) as Map<String, dynamic>),
    );
    expect(a.scores.single.score, isNull);
    expect(a.nutritionPercent, isEmpty);
    expect(a.average('stress'), 4.2);
    expect(a.change('stress_change_percent'), isNull);
  });
}
