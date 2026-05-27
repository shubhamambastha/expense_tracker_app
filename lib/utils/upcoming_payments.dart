import '../models/account.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';

/// Compute the next occurrence date for a recurring transaction.
///
/// Single source of truth for "when is this due next?" — used by the
/// transaction detail sheet (via [TransactionDetailViewData.nextPaymentDate])
/// and the Upcoming Payments section on the dashboard. Future notification
/// jobs can call this directly.
DateTime? computeNextPaymentDate(Transaction transaction, {DateTime? now}) {
  if (!transaction.isRecurring) return null;
  final frequency =
      transaction.recurrenceFrequency ?? RecurrenceFrequency.monthly;
  final start = transaction.recurrenceStartDate ?? transaction.date;
  final end = transaction.recurrenceEndDate;
  return _computeNextOccurrence(
    start: start,
    frequency: frequency,
    end: end,
    now: now,
  );
}

/// A recurring transaction projected to its next due date, ready for the
/// upcoming-payments section.
class UpcomingPayment {
  const UpcomingPayment({
    required this.transaction,
    required this.dueDate,
    required this.daysUntil,
    this.account,
  });

  final Transaction transaction;
  final DateTime dueDate;

  /// 0 = today, 1 = tomorrow, etc. Negative values are filtered out.
  final int daysUntil;
  final Account? account;

  bool get isAutoDeduct => transaction.isRecurring;

  String get title => transaction.counterpartyName;
}

/// Returns recurring transactions whose next due date falls within
/// [withinDays] from [now], sorted by ascending due date.
List<UpcomingPayment> upcomingPaymentsFor(
  List<Transaction> transactions, {
  List<Account> accounts = const [],
  DateTime? now,
  int withinDays = 30,
}) {
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final cutoff = today.add(Duration(days: withinDays));

  final out = <UpcomingPayment>[];
  for (final tx in transactions) {
    if (!tx.isRecurring) continue;
    final next = computeNextPaymentDate(tx, now: clock);
    if (next == null) continue;
    final nextDay = DateTime(next.year, next.month, next.day);
    if (nextDay.isBefore(today)) continue;
    if (nextDay.isAfter(cutoff)) continue;

    Account? account;
    for (final a in accounts) {
      if (a.id == tx.accountId) {
        account = a;
        break;
      }
    }

    out.add(
      UpcomingPayment(
        transaction: tx,
        dueDate: next,
        daysUntil: nextDay.difference(today).inDays,
        account: account,
      ),
    );
  }

  out.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return out;
}

/// Short relative label: "Today", "Tomorrow", "In 3 days", "In 2 weeks".
String upcomingDueLabel(int daysUntil) {
  if (daysUntil <= 0) return 'Today';
  if (daysUntil == 1) return 'Tomorrow';
  if (daysUntil < 7) return 'In $daysUntil days';
  if (daysUntil < 14) return 'Next week';
  if (daysUntil < 30) {
    final weeks = (daysUntil / 7).round();
    return 'In $weeks weeks';
  }
  return 'In a month';
}

DateTime? _computeNextOccurrence({
  required DateTime start,
  required RecurrenceFrequency frequency,
  DateTime? end,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  var next = start;

  if (next.isAfter(clock)) {
    if (end != null && next.isAfter(end)) return null;
    return next;
  }

  for (var i = 0; i < 500; i++) {
    next = _stepForward(next, frequency);
    if (end != null && next.isAfter(end)) return null;
    if (next.isAfter(clock)) return next;
  }

  return null;
}

DateTime _stepForward(DateTime date, RecurrenceFrequency frequency) {
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return date.add(const Duration(days: 1));
    case RecurrenceFrequency.weekly:
      return date.add(const Duration(days: 7));
    case RecurrenceFrequency.monthly:
      return DateTime(date.year, date.month + 1, date.day, date.hour,
          date.minute, date.second);
    case RecurrenceFrequency.quarterly:
      return DateTime(date.year, date.month + 3, date.day, date.hour,
          date.minute, date.second);
    case RecurrenceFrequency.yearly:
      return DateTime(date.year + 1, date.month, date.day, date.hour,
          date.minute, date.second);
    case RecurrenceFrequency.custom:
      return date.add(const Duration(days: 30));
  }
}
