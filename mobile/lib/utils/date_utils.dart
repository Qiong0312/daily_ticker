import 'package:intl/intl.dart';

import '../models/types.dart';

String todayKey([DateTime? ref]) => formatDateKey(ref ?? DateTime.now());

String formatDateKey(DateTime date) {
  final y = date.year;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String formatDisplayDate(DateTime date) {
  return DateFormat('EEEE, MMMM d', 'en_US').format(date);
}

const weekStartsOn = DateTime.monday;

DateTime startOfWeek(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final day = d.weekday;
  final diff = day == DateTime.sunday ? -6 : weekStartsOn - day;
  return d.add(Duration(days: diff));
}

DateTime endOfWeek(DateTime date) {
  final start = startOfWeek(date);
  return DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
}

String formatWeekRange([DateTime? ref]) {
  final start = startOfWeek(ref ?? DateTime.now());
  final end = endOfWeek(ref ?? DateTime.now());

  if (start.month == end.month) {
    final month = DateFormat('MMM', 'en_US').format(start);
    return '$month ${start.day}–${end.day}';
  }

  final startLabel = DateFormat('MMM d', 'en_US').format(start);
  final endLabel = DateFormat('MMM d', 'en_US').format(end);
  return '$startLabel – $endLabel';
}

DateTime startOfMonth(DateTime date) {
  return DateTime(date.year, date.month);
}

DateTime startOfYear(DateTime date) {
  return DateTime(date.year);
}

bool isDateInRange(String dateKey, DateTime start, DateTime end) {
  final startKey = formatDateKey(start);
  final endKey = formatDateKey(end);
  return dateKey.compareTo(startKey) >= 0 && dateKey.compareTo(endKey) <= 0;
}

DateTime parseDateKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

({DateTime start, DateTime end}) getPeriodRange(Period period, [DateTime? ref]) {
  final now = ref ?? DateTime.now();
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

  switch (period) {
    case Period.week:
      return (start: startOfWeek(now), end: end);
    case Period.month:
      return (start: startOfMonth(now), end: end);
    case Period.year:
      return (start: startOfYear(now), end: end);
  }
}

int getDaysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

String formatMonthYear(DateTime date) {
  return DateFormat('MMMM yyyy', 'en_US').format(date);
}

String formatDayRecapDate(String dateKey) {
  return DateFormat('EEEE, MMMM d', 'en_US').format(parseDateKey(dateKey));
}
