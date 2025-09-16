import 'package:intl/intl.dart';

class AppDateUtils {
  const AppDateUtils._();

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String formatShort(DateTime date) => DateFormat.MMMd().format(date);

  static String formatMedium(DateTime date) => DateFormat.yMMMd().format(date);

  static String formatFull(DateTime date) => DateFormat.yMMMMd().format(date);

  static String formatDayNumber(DateTime date) => DateFormat.d().format(date);
}
