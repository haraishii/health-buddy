import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_buddy/data/api/api_client.dart';
import 'package:health_buddy/data/api/session.dart';
import 'package:health_buddy/features/food/presentation/pages/photo_result_screen.dart';
import 'package:health_buddy/features/food/presentation/pages/scan_meal_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const _user = {
  'id': 1,
  'email': 'annida@example.com',
  'name': 'Annida',
  'status': 'Student',
  'life_stage': 'general',
  'created_at': '2026-05-01T08:00:00Z',
};

const _oneItem = {
  'model': 'gemma4:31b',
  'items': [
    {
      'name': 'Nasi putih',
      'name_en': 'white rice',
      'grams': 150,
      'calories_kcal': 195,
      'protein_g': 4,
      'carbs_g': 42,
      'fat_g': 0.4,
      'fiber_g': 0.6,
      'confidence': 1,
      'box': {'x_min': 300, 'y_min': 300, 'x_max': 700, 'y_max': 700},
      'source': 'database',
      'food_id': 'MK011',
      'serving_grams': 100,
    },
  ],
  'unrecognized': <String>[],
};

/// What "preparing" the photo returns in these tests, so we can see it is what gets uploaded.
final Uint8List _preparedBytes = img.encodeJpg(img.Image(width: 2, height: 2));
Future<Uint8List> _prepared(Uint8List photo) async => _preparedBytes;

/// The base64 images the fake backend received on /me/meals/photo.
final _sentImages = <String>[];

/// A signed-in session whose backend answers the food search with nothing and /me/meals/photo with [photo].
Future<Session> _session(Future<http.Response> Function() photo) async {
  _sentImages.clear();
  final session = Session(
    store: MemorySessionStore({'auth_token': 'test-token', 'auth_user': jsonEncode(_user)}),
    client: ApiClient(
      baseUrl: 'http://test',
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v1/me/meals/photo') {
          _sentImages.add((jsonDecode(request.body) as Map<String, dynamic>)['image'] as String);
          return photo();
        }
        return http.Response(jsonEncode({'items': <Object>[], 'limit': 30, 'offset': 0}), 200);
      }),
    ),
  );
  await session.restore();
  return session;
}

void main() {
  testWidgets('analysis error keeps the photo and retries', (tester) async {
    var calls = 0;
    var picks = 0;
    final session = await _session(() async {
      calls++;
      return calls == 1
          ? http.Response(jsonEncode({'error': 'Photo analysis failed. Try again or add the food manually.'}), 502)
          : http.Response(jsonEncode(_oneItem), 200);
    });
    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: MaterialApp(
          home: ScanMealScreen(
            pickImage: (_) async {
              picks++;
              return XFile.fromData(_png, name: 'meal.jpg');
            },
            preparePhoto: _prepared,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Photo analysis failed. Try again or add the food manually.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoResultScreen), findsOneWidget);
    expect(picks, 1);
    expect(calls, 2);
    // Both attempts upload the prepared (rotated, EXIF-free) photo, not the picked bytes.
    expect(_sentImages, [base64Encode(_preparedBytes), base64Encode(_preparedBytes)]);
  });

  testWidgets('an unexpected error ends the analysis with a retryable message', (tester) async {
    final session = await _session(() async => http.Response('<html>captive portal</html>', 200));
    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: MaterialApp(
          home: ScanMealScreen(
            pickImage: (_) async => XFile.fromData(_png, name: 'meal.jpg'),
            preparePhoto: _prepared,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(find.text('Analyzing your meal…'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('New photo after an error goes back to picking', (tester) async {
    final session = await _session(() async => http.Response(jsonEncode({'error': 'Nope.'}), 400));
    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: MaterialApp(
          home: ScanMealScreen(
            pickImage: (_) async => XFile.fromData(_png, name: 'meal.jpg'),
            preparePhoto: _prepared,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Nope.'), findsOneWidget);

    await tester.tap(find.text('New photo'));
    await tester.pumpAndSettle();
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Nope.'), findsNothing);
  });

  testWidgets('leaving during analysis does not open the result', (tester) async {
    final release = Completer<void>();
    final session = await _session(() async {
      await release.future;
      return http.Response(jsonEncode(_oneItem), 200);
    });
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ScanMealScreen(
          pickImage: (_) async => XFile.fromData(_png, name: 'meal.jpg'),
          preparePhoto: _prepared,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Analyzing your meal…'), findsOneWidget);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    release.complete();
    await tester.pumpAndSettle();

    expect(find.byType(PhotoResultScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
