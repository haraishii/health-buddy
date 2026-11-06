import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_buddy/data/api/api_client.dart';
import 'package:health_buddy/data/api/api_models.dart';
import 'package:health_buddy/data/api/health_buddy_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _rice = Food(
  id: 'MK011',
  name: 'Nasi putih',
  category: 'staple',
  serving: '1 centong (100 g)',
  servingGrams: 100,
  caloriesKcal: 130,
  proteinG: 2.7,
  carbsG: 28.2,
  fatG: 0.3,
  fiberG: 0.4,
  labels: [],
);

const _aiItem = PhotoItem(
  name: 'sambal ijo',
  grams: 100,
  caloriesKcal: 200,
  proteinG: 2,
  carbsG: 10,
  fatG: 16,
  fiberG: 4,
  confidence: 0.9,
  source: 'ai',
);

void main() {
  test('PhotoAnalysis.fromJson parses items and nullable box', () {
    final a = PhotoAnalysis.fromJson({
      'model': 'gemma4:31b',
      'items': [
        {
          'name': 'Nasi putih',
          'name_en': 'white rice',
          'grams': 200,
          'calories_kcal': 260,
          'protein_g': 5.4,
          'carbs_g': 56.4,
          'fat_g': 0.6,
          'fiber_g': 0.8,
          'confidence': 1,
          'box': {'x_min': 308, 'y_min': 286, 'x_max': 786, 'y_max': 908},
          'source': 'database',
          'food_id': 'MK011',
          'serving_grams': 100,
        },
        {
          'name': 'sambal ijo',
          'name_en': '',
          'grams': 30,
          'calories_kcal': 30,
          'protein_g': 0.5,
          'carbs_g': 3,
          'fat_g': 2,
          'fiber_g': 0,
          'confidence': 0.9,
          'box': null,
          'source': 'ai',
          'food_id': null,
          'serving_grams': null,
        },
      ],
      'unrecognized': ['blob'],
    });
    expect(a.model, 'gemma4:31b');
    expect(a.items, hasLength(2));
    expect(a.items[0].foodId, 'MK011');
    expect(a.items[0].box!.xMin, 308);
    expect(a.items[0].box!.yMax, 908);
    expect(a.items[1].box, isNull);
    expect(a.items[1].source, 'ai');
    expect(a.unrecognized, ['blob']);
  });

  test('fromFood scales by serving grams', () {
    final item = PhotoItem.fromFood(_rice, grams: 200);
    expect(item.caloriesKcal, closeTo(260, 0.001));
    expect(item.proteinG, closeTo(5.4, 0.001));
    expect(item.source, 'database');
    expect(item.foodId, 'MK011');
    expect(item.servingGrams, 100);
  });

  test('withGrams clamps and scales', () {
    expect(_aiItem.withGrams(150).caloriesKcal, closeTo(300, 0.001));
    expect(_aiItem.withGrams(150).fatG, closeTo(24, 0.001));
    final tiny = _aiItem.withGrams(2);
    expect(tiny.grams, 5);
    expect(tiny.caloriesKcal, closeTo(10, 0.001));
    expect(_aiItem.withGrams(5000).grams, 2000);
  });

  test('toBatchJson', () {
    expect(PhotoItem.fromFood(_rice, grams: 200).toBatchJson(), {'food_id': 'MK011', 'grams': 200.0});
    final custom = _aiItem.toBatchJson();
    expect(custom['grams'], 100.0);
    expect(custom['custom'], {
      'name': 'sambal ijo',
      'calories_kcal': 200.0,
      'protein_g': 2.0,
      'carbs_g': 10.0,
      'fat_g': 16.0,
      'fiber_g': 4.0,
    });
    expect(custom.containsKey('food_id'), isFalse);
  });

  test('MealLog.fromJson reads grams', () {
    Map<String, dynamic> log([Object? grams]) => {
      'id': 1,
      'logged_on': '2026-11-06',
      'meal_time': 'lunch',
      'name': 'Nasi putih',
      'category': 'staple',
      'servings': 2,
      'calories_kcal': 260,
      'protein_g': 5.4,
      'carbs_g': 56.4,
      'fat_g': 0.6,
      'labels': <String>[],
      'grams': ?grams,
    };
    expect(MealLog.fromJson(log(150)).grams, 150);
    expect(MealLog.fromJson(log()).grams, isNull);
  });

  test('analyzeMealPhoto posts the photo as base64 and addMealsBatch posts the items', () async {
    final sent = <String, Map<String, dynamic>>{};
    final api = HealthBuddyApi(
      ApiClient(
        baseUrl: 'http://test',
        httpClient: MockClient((r) async {
          sent[r.url.path] = jsonDecode(r.body) as Map<String, dynamic>;
          final body = r.url.path.endsWith('/photo')
              ? {'model': 'gemma4:31b', 'items': <Object>[], 'unrecognized': <Object>[]}
              : {'items': <Object>[]};
          return http.Response(jsonEncode(body), 200);
        }),
      ),
    );

    final analysis = await api.analyzeMealPhoto([0xFF, 0xD8, 0xFF]);
    expect(analysis.items, isEmpty);
    expect(sent['/api/v1/me/meals/photo'], {
      'image': base64Encode([0xFF, 0xD8, 0xFF]),
    });

    await api.addMealsBatch(mealTime: 'dinner', items: [_aiItem], date: DateTime(2026, 11, 5));
    final batch = sent['/api/v1/me/meals/batch']!;
    expect(batch['date'], '2026-11-05');
    expect(batch['meal_time'], 'dinner');
    expect((batch['items'] as List).single, _aiItem.toBatchJson());
  });
}
