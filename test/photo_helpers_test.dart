import 'package:flutter_test/flutter_test.dart';
import 'package:health_buddy/data/api/api_models.dart';
import 'package:health_buddy/features/food/meal_time.dart';
import 'package:health_buddy/features/food/presentation/widgets/photo_callouts.dart';

PhotoBox _box(double x, double y) => PhotoBox(xMin: x - 50, yMin: y - 50, xMax: x + 50, yMax: y + 50);

void main() {
  test('mealTimeAt follows the hour', () {
    String at(int h) => mealTimeAt(DateTime(2026, 11, 6, h));
    expect(at(7), 'breakfast');
    expect(at(12), 'lunch');
    expect(at(16), 'snack');
    expect(at(19), 'dinner');
    expect(at(23), 'snack');
  });

  test('parseExifDate reads the EXIF format and rejects bad or future dates', () {
    expect(parseExifDate('2026:11:04 19:30:05'), DateTime(2026, 11, 4, 19, 30, 5));
    expect(parseExifDate('garbage'), isNull);
    expect(parseExifDate(null), isNull);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final exif =
        '${tomorrow.year}:${tomorrow.month.toString().padLeft(2, '0')}:${tomorrow.day.toString().padLeft(2, '0')} '
        '12:00:00';
    expect(parseExifDate(exif), isNull);
  });

  test('layoutCallouts puts left foods on the left and right foods on the right', () {
    final specs = layoutCallouts([_box(200, 500), _box(800, 500)]);
    expect(specs, hasLength(2));
    expect(specs[0].index, 0);
    expect(specs[0].left, isTrue);
    expect(specs[0].labelY, 0.5);
    expect(specs[1].left, isFalse);
    expect(specs[1].labelY, 0.5);
    expect(specs[0].anchor.dx, closeTo(0.2, 1e-9));
    expect(specs.every((s) => s.showLabel), isTrue);
  });

  test('layoutCallouts skips foods without a box but keeps their numbers', () {
    final specs = layoutCallouts([null, _box(300, 300)]);
    expect(specs, hasLength(1));
    expect(specs.single.index, 1);
  });

  test('layoutCallouts orders a side top to bottom', () {
    final specs = layoutCallouts([_box(200, 800), _box(200, 200)]);
    final top = specs.firstWhere((s) => s.index == 1);
    final bottom = specs.firstWhere((s) => s.index == 0);
    expect(top.labelY, closeTo(1 / 3, 1e-9));
    expect(bottom.labelY, closeTo(2 / 3, 1e-9));
  });

  test('layoutCallouts shows only numbers on a crowded side', () {
    final specs = layoutCallouts([for (var i = 0; i < 5; i++) _box(200, 100.0 + i * 150)]);
    expect(specs, hasLength(5));
    expect(specs.every((s) => !s.showLabel), isTrue);
  });
}
