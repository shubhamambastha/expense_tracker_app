import '../models/account.dart';
import '../models/recurring_event.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import 'recurrence_normalization.dart' as recurrence_normalization;
import 'transaction_subtype_helpers.dart';
import 'upcoming_payments.dart';

/// View-model types and pure aggregations for the Recurring Payments Manager
/// screen.
///
/// All helpers are side-effect free and read from `List<Transaction>` +
/// `List<RecurringEvent>` so they can be moved behind a provider, memoised, or
/// pushed onto an isolate without touching the UI layer.

/// Time-bucketed groupings used by the upcoming-payments timeline.
enum UpcomingBucket { today, tomorrow, thisWeek, laterThisMonth }

extension UpcomingBucketX on UpcomingBucket {
  String get label {
    switch (this) {
      case UpcomingBucket.today:
        return 'Today';
      case UpcomingBucket.tomorrow:
        return 'Tomorrow';
      case UpcomingBucket.thisWeek:
        return 'This Week';
      case UpcomingBucket.laterThisMonth:
        return 'Later This Month';
    }
  }
}

/// Domain-flavour of a recurring schedule.
///
/// The persistence layer doesn't distinguish between subscriptions, EMIs and
/// generic recurring expenses — that classification is derived from the
/// transaction's `category` via [TransactionSubtypeHelpers]. Centralised here
/// so every section on the manager screen agrees on the split.
enum RecurringKind { subscription, emi, other }

extension RecurringKindX on RecurringKind {
  String get label {
    switch (this) {
      case RecurringKind.subscription:
        return 'Subscription';
      case RecurringKind.emi:
        return 'EMI';
      case RecurringKind.other:
        return 'Recurring expense';
    }
  }
}

/// One row in the upcoming-payments timeline, already projected to its next
/// real due date (events accounted for) with the resolved account.
class UpcomingPaymentItem {
  const UpcomingPaymentItem({
    required this.transaction,
    required this.dueDate,
    required this.daysUntil,
    required this.bucket,
    required this.kind,
    this.account,
  });

  final Transaction transaction;
  final DateTime dueDate;

  /// 0 = today, 1 = tomorrow, etc. Negative values are filtered upstream.
  final int daysUntil;
  final UpcomingBucket bucket;
  final RecurringKind kind;
  final Account? account;

  /// The recurring transaction's `reminderTiming` doubles as the auto-deduct
  /// signal: configured reminder → user wants a manual nudge; null → assume
  /// the schedule auto-deducts on the linked card/account.
  bool get isAutoDeduct => transaction.reminderTiming == null;
}

/// View model for one card in the Active Subscriptions / EMI Management /
/// Recurring Expenses sections.
class RecurringScheduleItem {
  const RecurringScheduleItem({
    required this.transaction,
    required this.kind,
    required this.nextDueDate,
    required this.monthlyEquivalent,
    this.account,
    this.lastEvent,
  });

  final Transaction transaction;
  final RecurringKind kind;

  /// Null when the schedule is paused or has ended.
  final DateTime? nextDueDate;
  final double monthlyEquivalent;
  final Account? account;

  /// Most-recent event for this schedule (any type). Drives the
  /// "Overdue / Last paid …" badge.
  final RecurringEvent? lastEvent;

  bool get isPaused => transaction.isPaused;
  bool get isAutoDeduct => transaction.reminderTiming == null && !isPaused;
}

/// Numeric progress for an EMI schedule. Driven entirely by the user-entered
/// start + end dates — we don't pretend to know the amortisation curve.
class EmiProgress {
  const EmiProgress({
    required this.completed,
    required this.total,
    required this.remainingMonths,
    required this.remainingPrincipal,
  });

  final int completed;
  final int total;
  final int remainingMonths;
  final double remainingPrincipal;

  double get completionRatio {
    if (total <= 0) return 0;
    return (completed / total).clamp(0, 1).toDouble();
  }
}

/// Top-level result of `RecurringManagement.build(...)` — populated once on
/// every page rebuild and passed down to every section.
class RecurringManagementSnapshot {
  const RecurringManagementSnapshot({
    required this.upcoming,
    required this.subscriptions,
    required this.emis,
    required this.other,
    required this.subscriptionsMonthly,
    required this.emisMonthly,
    required this.otherMonthly,
    required this.nextUpcoming,
  });

  /// All upcoming items within the lookahead window, sorted ascending.
  /// Keyed by [UpcomingBucket] in [upcomingByBucket].
  final List<UpcomingPaymentItem> upcoming;

  final List<RecurringScheduleItem> subscriptions;
  final List<RecurringScheduleItem> emis;
  final List<RecurringScheduleItem> other;

  final double subscriptionsMonthly;
  final double emisMonthly;
  final double otherMonthly;

  /// The very next upcoming payment across every section (or null if none).
  final UpcomingPaymentItem? nextUpcoming;

  double get totalMonthly =>
      subscriptionsMonthly + emisMonthly + otherMonthly;

  int get totalActive => subscriptions.length + emis.length + other.length;

  bool get isEmpty => totalActive == 0;

  Map<UpcomingBucket, List<UpcomingPaymentItem>> get upcomingByBucket {
    final out = <UpcomingBucket, List<UpcomingPaymentItem>>{
      for (final b in UpcomingBucket.values) b: <UpcomingPaymentItem>[],
    };
    for (final item in upcoming) {
      out[item.bucket]!.add(item);
    }
    return out;
  }
}

class RecurringManagement {
  RecurringManagement._();

  /// Build the full snapshot used by every section on the manager screen.
  ///
  /// [lookaheadDays] caps how far ahead the timeline reaches (default 60 so
  /// the "Later This Month" bucket has enough headroom around month-end).
  static RecurringManagementSnapshot build({
    required List<Transaction> transactions,
    required List<RecurringEvent> events,
    required List<Account> accounts,
    DateTime? now,
    int lookaheadDays = 60,
  }) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);
    final eventsByTx = _groupEventsByTransaction(events);
    final accountsById = {
      for (final a in accounts)
        if (a.id != null) a.id!: a,
    };

    final subscriptions = <RecurringScheduleItem>[];
    final emis = <RecurringScheduleItem>[];
    final other = <RecurringScheduleItem>[];
    final upcoming = <UpcomingPaymentItem>[];
    final seenSignatures = <String>{};
    var subsMonthly = 0.0;
    var emisMonthly = 0.0;
    var otherMonthly = 0.0;

    for (final tx in transactions) {
      if (!tx.isRecurring || !tx.isExpense) continue;
      // Closed schedules (user cancelled the subscription, marked the EMI
      // completed, etc.) disappear from every surface — no card, no
      // upcoming entry, no monthly total contribution.
      if (tx.isClosed) continue;

      // Recurring transactions may show up multiple times in the cache (one
      // per past occurrence). De-duplicate on a stable signature so the
      // sections don't list the same schedule twice.
      final signature = _scheduleSignature(tx);
      if (!seenSignatures.add(signature)) continue;

      final kind = classify(tx);
      final monthly = monthlyEquivalent(tx);
      final account = accountsById[tx.accountId];
      final txEvents = eventsByTx[tx.id] ?? const <RecurringEvent>[];
      final nextDue = nextDueWithEvents(
        transaction: tx,
        events: txEvents,
        now: clock,
      );
      final lastEvent = txEvents.isEmpty ? null : txEvents.first;

      final scheduleItem = RecurringScheduleItem(
        transaction: tx,
        kind: kind,
        nextDueDate: nextDue,
        monthlyEquivalent: monthly,
        account: account,
        lastEvent: lastEvent,
      );

      switch (kind) {
        case RecurringKind.subscription:
          subscriptions.add(scheduleItem);
          subsMonthly += monthly;
          break;
        case RecurringKind.emi:
          emis.add(scheduleItem);
          emisMonthly += monthly;
          break;
        case RecurringKind.other:
          other.add(scheduleItem);
          otherMonthly += monthly;
          break;
      }

      if (nextDue == null) continue;
      final nextDay = DateTime(nextDue.year, nextDue.month, nextDue.day);
      final daysUntil = nextDay.difference(today).inDays;
      if (daysUntil < 0 || daysUntil > lookaheadDays) continue;

      upcoming.add(
        UpcomingPaymentItem(
          transaction: tx,
          dueDate: nextDue,
          daysUntil: daysUntil,
          bucket: _bucketFor(daysUntil: daysUntil, today: today, due: nextDay),
          kind: kind,
          account: account,
        ),
      );
    }

    int byNextDue(RecurringScheduleItem a, RecurringScheduleItem b) {
      final ad = a.nextDueDate;
      final bd = b.nextDueDate;
      if (ad == null && bd == null) {
        return a.transaction.counterpartyName
            .compareTo(b.transaction.counterpartyName);
      }
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    }

    subscriptions.sort(byNextDue);
    emis.sort(byNextDue);
    other.sort(byNextDue);
    upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return RecurringManagementSnapshot(
      upcoming: upcoming,
      subscriptions: subscriptions,
      emis: emis,
      other: other,
      subscriptionsMonthly: subsMonthly,
      emisMonthly: emisMonthly,
      otherMonthly: otherMonthly,
      nextUpcoming: upcoming.isEmpty ? null : upcoming.first,
    );
  }

  /// Computes the next due date for a recurring transaction, honouring its
  /// pause state and any per-occurrence events the user has recorded.
  ///
  /// Algorithm:
  /// 1. If the transaction is paused or not recurring → `null`.
  /// 2. Walk the schedule forward from `recurrenceStartDate` (or `date`) one
  ///    cycle at a time using the same stepping used by
  ///    [computeNextPaymentDate].
  /// 3. For each candidate occurrence:
  ///    a. If a `paid` or `skipped` event exists for that occurrence → skip
  ///       past it.
  ///    b. If a `snoozed` event exists → defer to its `snoozeUntil` (still
  ///       only if it's after `now`).
  ///    c. Otherwise return that occurrence.
  static DateTime? nextDueWithEvents({
    required Transaction transaction,
    required List<RecurringEvent> events,
    DateTime? now,
  }) {
    // Paused → temporarily off the timeline; closed → permanently off.
    // Either way the manager treats them as having no next due date.
    if (!transaction.isRecurring ||
        transaction.isPaused ||
        transaction.isClosed) {
      return null;
    }
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);

    // Index events by their occurrence_date for O(1) lookup.
    final byDate = <String, List<RecurringEvent>>{};
    for (final event in events) {
      final key = _dateKey(event.occurrenceDate);
      byDate.putIfAbsent(key, () => []).add(event);
    }

    final frequency =
        transaction.recurrenceFrequency ?? RecurrenceFrequency.monthly;
    final start = transaction.recurrenceStartDate ?? transaction.date;
    final end = transaction.recurrenceEndDate;

    var candidate = start;
    // Catch up to "now" if the schedule started in the past — same loop
    // pattern as `upcoming_payments.dart`.
    for (var i = 0; i < 500; i++) {
      if (end != null && candidate.isAfter(end)) return null;

      final candidateDay =
          DateTime(candidate.year, candidate.month, candidate.day);
      final candidateEvents = byDate[_dateKey(candidate)] ?? const [];

      final paidOrSkipped = candidateEvents.any(
        (e) =>
            e.eventType == RecurringEventType.paid ||
            e.eventType == RecurringEventType.skipped,
      );
      if (paidOrSkipped) {
        candidate = _stepForward(candidate, frequency);
        continue;
      }

      RecurringEvent? snooze;
      for (final e in candidateEvents) {
        if (e.eventType == RecurringEventType.snoozed) {
          snooze = e;
          break;
        }
      }
      if (snooze != null && snooze.snoozeUntil != null) {
        final until = snooze.snoozeUntil!;
        if (!until.isBefore(today)) {
          return until;
        }
        // Snooze date has lapsed → treat as still-due today.
        candidate = today;
        continue;
      }

      if (!candidateDay.isBefore(today)) {
        return candidate;
      }
      candidate = _stepForward(candidate, frequency);
    }

    return null;
  }

  /// Classify a recurring transaction into subscription / EMI / other.
  static RecurringKind classify(Transaction transaction) {
    if (TransactionSubtypeHelpers.isEmiCategory(transaction.category)) {
      return RecurringKind.emi;
    }
    if (TransactionSubtypeHelpers.isSubscriptionCategory(transaction.category)) {
      return RecurringKind.subscription;
    }
    return RecurringKind.other;
  }

  /// Normalise the recurring amount to a per-month figure.
  static double monthlyEquivalent(Transaction transaction) =>
      recurrence_normalization.monthlyEquivalent(transaction);

  /// Computes EMI progress purely from the user-entered schedule. Returns
  /// null for non-EMI transactions or EMIs without an end date.
  static EmiProgress? emiProgress(Transaction transaction, {DateTime? now}) {
    if (!TransactionSubtypeHelpers.isEmiCategory(transaction.category)) {
      return null;
    }
    final start = transaction.recurrenceStartDate ?? transaction.date;
    final end = transaction.recurrenceEndDate;
    if (end == null) return null;

    final clock = now ?? DateTime.now();
    final totalMonths =
        ((end.year - start.year) * 12 + (end.month - start.month) + 1)
            .clamp(1, 999);
    final elapsedMonths =
        ((clock.year - start.year) * 12 + (clock.month - start.month))
            .clamp(0, totalMonths);
    final remainingMonths = (totalMonths - elapsedMonths).clamp(0, totalMonths);

    return EmiProgress(
      completed: elapsedMonths,
      total: totalMonths,
      remainingMonths: remainingMonths,
      remainingPrincipal: remainingMonths * transaction.amount,
    );
  }

  /// Returns the most-recently recorded event for [transactionId], or null.
  /// Useful for "Last paid …" badges on the schedule cards.
  static RecurringEvent? lastEventFor(
    int? transactionId,
    List<RecurringEvent> events,
  ) {
    if (transactionId == null) return null;
    RecurringEvent? best;
    for (final event in events) {
      if (event.transactionId != transactionId) continue;
      if (best == null || event.occurrenceDate.isAfter(best.occurrenceDate)) {
        best = event;
      }
    }
    return best;
  }

  // ---- internals -----------------------------------------------------------

  static Map<int, List<RecurringEvent>> _groupEventsByTransaction(
    List<RecurringEvent> events,
  ) {
    final out = <int, List<RecurringEvent>>{};
    for (final event in events) {
      out.putIfAbsent(event.transactionId, () => []).add(event);
    }
    // Newest first so callers using .first get the latest event.
    for (final list in out.values) {
      list.sort((a, b) => b.occurrenceDate.compareTo(a.occurrenceDate));
    }
    return out;
  }

  static String _scheduleSignature(Transaction tx) {
    if (tx.id != null) return 'id:${tx.id}';
    return 'sig:${tx.counterpartyName.toLowerCase()}|'
        '${tx.amount.toStringAsFixed(2)}|'
        '${tx.recurrenceFrequency?.name ?? ''}';
  }

  static String _dateKey(DateTime when) {
    final y = when.year.toString().padLeft(4, '0');
    final m = when.month.toString().padLeft(2, '0');
    final d = when.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static UpcomingBucket _bucketFor({
    required int daysUntil,
    required DateTime today,
    required DateTime due,
  }) {
    if (daysUntil <= 0) return UpcomingBucket.today;
    if (daysUntil == 1) return UpcomingBucket.tomorrow;
    if (daysUntil <= 7) return UpcomingBucket.thisWeek;
    if (due.year == today.year && due.month == today.month) {
      return UpcomingBucket.laterThisMonth;
    }
    return UpcomingBucket.laterThisMonth;
  }

  static DateTime _stepForward(DateTime date, RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return date.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return DateTime(
          date.year,
          date.month + 1,
          date.day,
          date.hour,
          date.minute,
          date.second,
        );
      case RecurrenceFrequency.quarterly:
        return DateTime(
          date.year,
          date.month + 3,
          date.day,
          date.hour,
          date.minute,
          date.second,
        );
      case RecurrenceFrequency.yearly:
        return DateTime(
          date.year + 1,
          date.month,
          date.day,
          date.hour,
          date.minute,
          date.second,
        );
      case RecurrenceFrequency.custom:
        return date.add(const Duration(days: 30));
    }
  }
}

/// Short relative label re-exported so the manager screen can render the same
/// "Today / Tomorrow / In 3 days" copy as the dashboard's upcoming card.
String upcomingDueLabelFor(int daysUntil) => upcomingDueLabel(daysUntil);
