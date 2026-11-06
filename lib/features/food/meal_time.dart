/// Meal times as the backend names them, with their labels.
const mealTimes = [('breakfast', 'Breakfast'), ('lunch', 'Lunch'), ('dinner', 'Dinner'), ('snack', 'Snack')];

/// Breakfast before 10, lunch before 15, snack before 18, then dinner (until 22), else snack.
String mealTimeAt(DateTime t) {
  final h = t.hour;
  if (h < 10) return 'breakfast';
  if (h < 15) return 'lunch';
  if (h < 18) return 'snack';
  if (h < 22) return 'dinner';
  return 'snack';
}

final _exifDate = RegExp(r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})');

/// When a photo was taken, from its EXIF DateTimeOriginal ("2026:11:04 19:30:05").
/// Null when missing, malformed (e.g. the "0000:00:00" placeholder) or in the future.
DateTime? parseExifDate(String? value) {
  final m = _exifDate.firstMatch(value?.trim() ?? '');
  if (m == null) return null;
  final p = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
  final d = DateTime(p[0], p[1], p[2], p[3], p[4], p[5]);
  // DateTime rolls invalid dates over (month 0, Feb 31), so a changed month or day means it was invalid.
  if (d.month != p[1] || d.day != p[2] || d.isAfter(DateTime.now())) return null;
  return d;
}
