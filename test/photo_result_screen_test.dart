import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_buddy/data/api/api_client.dart';
import 'package:health_buddy/data/api/api_models.dart';
import 'package:health_buddy/data/api/session.dart';
import 'package:health_buddy/features/food/presentation/pages/photo_result_screen.dart';
import 'package:health_buddy/widgets/common.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const _rice = PhotoItem(
  name: 'Nasi putih',
  grams: 100,
  caloriesKcal: 200,
  proteinG: 4,
  carbsG: 40,
  fatG: 1,
  fiberG: 1,
  source: 'database',
  foodId: 'MK011',
  servingGrams: 100,
  box: PhotoBox(xMin: 100, yMin: 100, xMax: 300, yMax: 300),
);

const _sambal = PhotoItem(
  name: 'sambal ijo',
  grams: 50,
  caloriesKcal: 50,
  proteinG: 1,
  carbsG: 3,
  fatG: 4,
  fiberG: 1,
  confidence: 0.9,
  source: 'ai',
  box: PhotoBox(xMin: 600, yMin: 500, xMax: 900, yMax: 800),
);

Future<void> _pump(WidgetTester tester, List<PhotoItem> items) async {
  final now = DateTime.now();
  await tester.pumpWidget(
    MaterialApp(
      home: PhotoResultScreen(
        image: _png,
        analysis: PhotoAnalysis(model: 'gemma4:31b', items: items, unrecognized: const []),
        takenAt: DateTime(now.year, now.month, now.day, 12),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _deleteFirst(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('photo-item-edit-0')));
  await _tap(tester, find.text('Delete'));
}

void main() {
  testWidgets('shows totals and updates them', (tester) async {
    await _pump(tester, [_rice, _sambal]);
    expect(find.text('250 kcal'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('photo-item-plus-0')));
    expect(find.text('110 g'), findsOneWidget);
    expect(find.text('270 kcal'), findsOneWidget);
  });

  testWidgets('delete via sheet removes the item', (tester) async {
    await _pump(tester, [_rice, _sambal]);
    await _deleteFirst(tester);

    expect(find.text('Nasi putih'), findsNothing);
    expect(find.text('sambal ijo'), findsOneWidget);
    expect(find.text('50 kcal'), findsOneWidget);
  });

  testWidgets('save is disabled with no items', (tester) async {
    await _pump(tester, [_rice, _sambal]);
    await _deleteFirst(tester);
    await _deleteFirst(tester);

    final save = tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'Save to log'));
    expect(save.onTap, isNull);
  });

  testWidgets('shows empty state when nothing was found', (tester) async {
    await _pump(tester, const []);
    expect(find.text('No food found in this photo'), findsOneWidget);
    expect(find.text('Add manually'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
  });

  testWidgets('Add manually puts a database food in the list at its serving weight', (tester) async {
    final session = Session(
      store: MemorySessionStore({
        'auth_token': 't',
        'auth_user': jsonEncode({
          'id': 1,
          'email': 'a@example.com',
          'name': 'A',
          'status': 'Student',
          'life_stage': 'general',
          'created_at': '2026-05-01T08:00:00Z',
        }),
      }),
      client: ApiClient(
        baseUrl: 'http://test',
        httpClient: MockClient(
          (r) async => http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'MK021',
                  'name': 'Tempe goreng',
                  'category': 'plant-based side dish',
                  'serving': '1 potong (50 g)',
                  'serving_grams': 50,
                  'calories_kcal': 118,
                  'protein_g': 9,
                  'carbs_g': 4,
                  'fat_g': 8,
                  'fiber_g': 1,
                  'labels': <String>[],
                },
              ],
              'limit': 30,
              'offset': 0,
            }),
            200,
          ),
        ),
      ),
    );
    await session.restore();
    final now = DateTime.now();
    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: MaterialApp(
          home: PhotoResultScreen(
            image: _png,
            analysis: const PhotoAnalysis(model: 'gemma4:31b', items: [_rice], unrecognized: []),
            takenAt: DateTime(now.year, now.month, now.day, 12),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(tester, find.text('Add manually'));
    await _tap(tester, find.text('Tempe goreng'));

    expect(find.text('Tempe goreng'), findsOneWidget);
    expect(find.text('50 g'), findsOneWidget);
    expect(find.text('318 kcal'), findsOneWidget); // 200 + 118
  });

  testWidgets('preselects lunch from takenAt', (tester) async {
    await _pump(tester, [_rice]);
    expect(tester.widget<Segmented>(find.byType(Segmented)).index, 1);
    expect(find.text('Today'), findsOneWidget);
  });
}
