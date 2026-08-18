import 'package:intl/intl.dart';

import '../models/transaction.dart';

/// Chronological bucket labels for the transaction list.
enum TransactionGroupKey {
  today,
  yesterday,
  earlierThisWeek,
  thisMonth,
  olderMonth,
}

class TransactionGroup {
  const TransactionGroup({
    required this.key,
    required this.label,
    required this.items,
  });

  final TransactionGroupKey key;
  final String label;
  final List<Transaction> items;

  /// Income minus expenses for the group (transfers excluded, since they
  /// don't change net worth). Shown next to the group label, matching the
  /// iOS redesign's per-day/period net total.
  double get netTotal {
    var net = 0.0;
    for (final t in items) {
      if (t.isIncome) net += t.amount;
      if (t.isExpense) net -= t.amount;
    }
    return net;
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isThisWeek(DateTime date, DateTime now) {
  final startOfWeek = _dateOnly(now.subtract(Duration(days: now.weekday - 1)));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));
  final d = _dateOnly(date);
  return !d.isBefore(startOfWeek) && !d.isAfter(endOfWeek);
}

bool _isThisMonth(DateTime date, DateTime now) =>
    date.year == now.year && date.month == now.month;

TransactionGroupKey _groupKeyForDate(DateTime date, DateTime now) {
  final today = _dateOnly(now);
  final d = _dateOnly(date);

  if (_isSameDay(d, today)) return TransactionGroupKey.today;

  final yesterday = today.subtract(const Duration(days: 1));
  if (_isSameDay(d, yesterday)) return TransactionGroupKey.yesterday;

  if (_isThisWeek(d, now) && d.isBefore(yesterday)) {
    return TransactionGroupKey.earlierThisWeek;
  }

  if (_isThisMonth(d, now)) return TransactionGroupKey.thisMonth;

  return TransactionGroupKey.olderMonth;
}

String _labelForKey(TransactionGroupKey key, DateTime sampleDate) {
  switch (key) {
    case TransactionGroupKey.today:
      return 'Today';
    case TransactionGroupKey.yesterday:
      return 'Yesterday';
    case TransactionGroupKey.earlierThisWeek:
      return 'Earlier This Week';
    case TransactionGroupKey.thisMonth:
      return 'This Month';
    case TransactionGroupKey.olderMonth:
      return DateFormat.yMMMM().format(sampleDate);
  }
}

/// Groups transactions in display order (newest groups first).
List<TransactionGroup> groupTransactionsByDate(
  List<Transaction> transactions, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final buckets = <TransactionGroupKey, List<Transaction>>{};
  final sampleDates = <TransactionGroupKey, DateTime>{};

  for (final tx in transactions) {
    final key = _groupKeyForDate(tx.date, clock);
    buckets.putIfAbsent(key, () => []).add(tx);
    sampleDates.putIfAbsent(key, () => tx.date);
  }

  const order = [
    TransactionGroupKey.today,
    TransactionGroupKey.yesterday,
    TransactionGroupKey.earlierThisWeek,
    TransactionGroupKey.thisMonth,
    TransactionGroupKey.olderMonth,
  ];

  final monthGroups = <String, List<Transaction>>{};
  for (final tx in buckets[TransactionGroupKey.olderMonth] ?? const []) {
    final label = DateFormat.yMMMM().format(tx.date);
    monthGroups.putIfAbsent(label, () => []).add(tx);
  }

  final result = <TransactionGroup>[];

  for (final key in order) {
    if (key == TransactionGroupKey.olderMonth) {
      final sortedLabels = monthGroups.keys.toList()
        ..sort((a, b) {
          final da = DateFormat.yMMMM().parse(a);
          final db = DateFormat.yMMMM().parse(b);
          return db.compareTo(da);
        });
      for (final label in sortedLabels) {
        result.add(TransactionGroup(
          key: key,
          label: label,
          items: monthGroups[label]!,
        ));
      }
      continue;
    }

    final items = buckets[key];
    if (items == null || items.isEmpty) continue;
    result.add(TransactionGroup(
      key: key,
      label: _labelForKey(key, sampleDates[key]!),
      items: items,
    ));
  }

  return result;
}
