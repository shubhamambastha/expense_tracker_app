import 'package:intl/intl.dart';

/// Formats a transaction date for detail views: `Today • 7:42 PM`.
String formatTransactionDetailDateTime(DateTime date) {
  final now = DateTime.now();
  final timeLabel = DateFormat.jm().format(date);

  if (_isSameDay(date, now)) {
    return 'Today • $timeLabel';
  }

  final yesterday = now.subtract(const Duration(days: 1));
  if (_isSameDay(date, yesterday)) {
    return 'Yesterday • $timeLabel';
  }

  final dateLabel = DateFormat.MMMd().format(date);
  return '$dateLabel • $timeLabel';
}

/// Formats a date-only value for metadata rows.
String formatTransactionDetailDate(DateTime date) {
  return DateFormat.yMMMd().format(date);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
