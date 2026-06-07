import 'package:intl/intl.dart';

class DateHelper {
  /// Formats date to a human readable short string (e.g. "02 Jun 2026")
  static String formatShort(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Formats date to long calendar style (e.g. "Tuesday, June 2, 2026")
  static String formatLong(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  /// Formats time (e.g. "05:30 PM")
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Returns relative descriptors like "Today", "Yesterday", or the date
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) {
      return "Today";
    } else if (compareDate == yesterday) {
      return "Yesterday";
    } else {
      return formatShort(date);
    }
  }
}
