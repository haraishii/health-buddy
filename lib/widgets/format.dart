// Display formatting for numbers and dates that come from the API.

import 'common.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// 42 -> "42", 42.5 -> "42.5"; thousands get commas: 6240 -> "6,240".
String fmtNum(num value, {int decimals = 0}) {
  if (decimals == 0 || value == value.roundToDouble()) return fmtThousands(value);
  return value.toStringAsFixed(decimals);
}

/// 6.17 -> "6 h 10 m", 8 -> "8 h".
String fmtHours(double hours) {
  final total = (hours * 60).round();
  final h = total ~/ 60, m = total % 60;
  return m == 0 ? '$h h' : '$h h $m m';
}

/// 1250 -> "1.25 L", 2000 -> "2 L".
String fmtLiters(double ml) {
  final l = ml / 1000;
  return '${l.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')} L';
}

/// 12 -> "↑ 12%", -15 -> "↓ 15%", null -> "–".
String fmtChange(double? percent) {
  if (percent == null) return '–';
  if (percent == 0) return '0%';
  return '${percent > 0 ? '↑' : '↓'} ${percent.abs().round()}%';
}

DateTime parseApiDate(String s) => DateTime.parse(s);

/// "Today, Sunday May 18" for today, otherwise "Saturday May 17".
String fmtDayTitle(DateTime d) {
  final now = DateTime.now();
  final label = '${_weekdays[d.weekday - 1]} ${_months[d.month - 1]} ${d.day}';
  return d.year == now.year && d.month == now.month && d.day == now.day ? 'Today, $label' : label;
}

/// "Mon", "Tue", ...
String fmtWeekdayShort(DateTime d) => _weekdays[d.weekday - 1].substring(0, 3);

/// "M", "T", ...
String fmtWeekdayLetter(DateTime d) => _weekdays[d.weekday - 1].substring(0, 1);

/// "May 12 – 18" or "Apr 28 – May 4".
String fmtRange(DateTime from, DateTime to) {
  String m(DateTime d) => _months[d.month - 1].substring(0, 3);
  return from.month == to.month ? '${m(from)} ${from.day} – ${to.day}' : '${m(from)} ${from.day} – ${m(to)} ${to.day}';
}

/// "May 2026"
String fmtMonthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

/// "May 15"
String fmtShortDate(DateTime d) => '${_months[d.month - 1].substring(0, 3)} ${d.day}';

/// "9:41"
String fmtTime(DateTime d) => '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

/// "22:30" -> "10:30 PM"
String fmtClock(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.parse(parts[0]), m = parts[1];
  final suffix = h < 12 ? 'AM' : 'PM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m $suffix';
}

/// Monday of the week that contains [d].
DateTime weekStart(DateTime d) => DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
