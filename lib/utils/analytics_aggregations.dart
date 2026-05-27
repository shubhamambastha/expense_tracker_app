import '../models/category_budget.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import 'transaction_subtype_helpers.dart';

/// The selectable analytics period.
///
/// Maps cleanly to a [DateTimeRange] via [AnalyticsRangeX.resolve]; trend
/// buckets and label formatting are derived from the same enum so every
/// section stays in sync.
enum AnalyticsRange {
  thisWeek,
  thisMonth,
  lastMonth,
  threeMonths,
  sixMonths,
  thisYear,
  custom,
}

extension AnalyticsRangeX on AnalyticsRange {
  String get label {
    switch (this) {
      case AnalyticsRange.thisWeek:
        return 'This Week';
      case AnalyticsRange.thisMonth:
        return 'This Month';
      case AnalyticsRange.lastMonth:
        return 'Last Month';
      case AnalyticsRange.threeMonths:
        return '3 Months';
      case AnalyticsRange.sixMonths:
        return '6 Months';
      case AnalyticsRange.thisYear:
        return 'This Year';
      case AnalyticsRange.custom:
        return 'Custom';
    }
  }

  /// True when the range spans multiple months — used to switch between
  /// daily and monthly buckets in trend charts.
  bool get isMultiMonth {
    switch (this) {
      case AnalyticsRange.thisWeek:
      case AnalyticsRange.thisMonth:
      case AnalyticsRange.lastMonth:
        return false;
      case AnalyticsRange.threeMonths:
      case AnalyticsRange.sixMonths:
      case AnalyticsRange.thisYear:
      case AnalyticsRange.custom:
        return true;
    }
  }

  /// Resolve the range to a concrete [start, end] window (inclusive).
  ResolvedRange resolve({DateTime? now, ResolvedRange? customRange}) {
    final clock = _atStartOfDay(now ?? DateTime.now());
    switch (this) {
      case AnalyticsRange.thisWeek:
        final startOfWeek = clock.subtract(Duration(days: clock.weekday - 1));
        return ResolvedRange(start: startOfWeek, end: _endOfDay(clock));
      case AnalyticsRange.thisMonth:
        return ResolvedRange(
          start: DateTime(clock.year, clock.month, 1),
          end: _endOfDay(clock),
        );
      case AnalyticsRange.lastMonth:
        final firstOfThis = DateTime(clock.year, clock.month, 1);
        final lastMonthStart = DateTime(clock.year, clock.month - 1, 1);
        final lastMonthEnd =
            firstOfThis.subtract(const Duration(milliseconds: 1));
        return ResolvedRange(start: lastMonthStart, end: lastMonthEnd);
      case AnalyticsRange.threeMonths:
        final start = DateTime(clock.year, clock.month - 2, 1);
        return ResolvedRange(start: start, end: _endOfDay(clock));
      case AnalyticsRange.sixMonths:
        final start = DateTime(clock.year, clock.month - 5, 1);
        return ResolvedRange(start: start, end: _endOfDay(clock));
      case AnalyticsRange.thisYear:
        return ResolvedRange(
          start: DateTime(clock.year, 1, 1),
          end: _endOfDay(clock),
        );
      case AnalyticsRange.custom:
        return customRange ??
            ResolvedRange(
              start: DateTime(clock.year, clock.month, 1),
              end: _endOfDay(clock),
            );
    }
  }
}

/// A concrete date window with inclusive [start] and [end].
class ResolvedRange {
  const ResolvedRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get inclusiveDays => end.difference(start).inDays + 1;

  /// Same-length window immediately preceding [this] — used for
  /// month-over-month deltas.
  ResolvedRange get previous {
    final days = inclusiveDays;
    final prevEnd = start.subtract(const Duration(milliseconds: 1));
    final prevStart = prevEnd.subtract(Duration(days: days - 1));
    return ResolvedRange(
      start: _atStartOfDay(prevStart),
      end: _endOfDay(prevEnd),
    );
  }

  bool contains(DateTime when) {
    return !when.isBefore(start) && !when.isAfter(end);
  }
}

DateTime _atStartOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

/// High-level totals for a period.
class AnalyticsOverview {
  const AnalyticsOverview({
    required this.totalSpent,
    required this.totalIncome,
    required this.netSavings,
    required this.averageDailySpend,
    required this.spentDelta,
    required this.incomeDelta,
    required this.savingsRate,
  });

  final double totalSpent;
  final double totalIncome;
  final double netSavings;
  final double averageDailySpend;

  /// Percent change vs the previous comparable period (null when prior has
  /// no signal, e.g. zero spending).
  final double? spentDelta;
  final double? incomeDelta;

  /// Net savings / total income — null when there's no income recorded.
  final double? savingsRate;
}

/// Per-category aggregate, sorted by descending [total].
class CategorySlice {
  const CategorySlice({
    required this.category,
    required this.total,
    required this.share,
    required this.transactionCount,
    required this.deltaPct,
  });

  final String category;
  final double total;
  final double share;
  final int transactionCount;

  /// Percent change vs the previous comparable window. Null when prior was
  /// zero or absent.
  final double? deltaPct;
}

/// Income / expense / savings totals for a single bucket (week, month, etc.).
class PeriodBucket {
  const PeriodBucket({
    required this.label,
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
  });

  final String label;
  final DateTime start;
  final DateTime end;
  final double income;
  final double expense;

  double get net => income - expense;
  double? get savingsRate => income <= 0 ? null : (income - expense) / income;
}

/// Subscription / recurring monthly burden, normalised to a per-month figure.
class RecurringCommitment {
  const RecurringCommitment({
    required this.transaction,
    required this.monthlyEquivalent,
    required this.isSubscription,
    required this.isEmi,
  });

  final Transaction transaction;
  final double monthlyEquivalent;
  final bool isSubscription;
  final bool isEmi;
}

class RecurringSummary {
  const RecurringSummary({
    required this.commitments,
    required this.subscriptionsTotal,
    required this.emiTotal,
    required this.totalMonthly,
  });

  final List<RecurringCommitment> commitments;
  final double subscriptionsTotal;
  final double emiTotal;
  final double totalMonthly;

  bool get isEmpty => commitments.isEmpty;
}

/// Pure aggregation helpers used by every analytics section.
///
/// All methods are side-effect free so we can swap them with cached
/// providers (or move them to an isolate) without touching the UI.
class AnalyticsAggregations {
  AnalyticsAggregations._();

  // --- Overview -----------------------------------------------------------

  static AnalyticsOverview overview({
    required List<Transaction> transactions,
    required ResolvedRange range,
  }) {
    final inWindow = _within(transactions, range);
    final prior = _within(transactions, range.previous);

    final spent = _sumExpenses(inWindow);
    final income = _sumIncome(inWindow);
    final priorSpent = _sumExpenses(prior);
    final priorIncome = _sumIncome(prior);
    final days = range.inclusiveDays.clamp(1, 366);

    return AnalyticsOverview(
      totalSpent: spent,
      totalIncome: income,
      netSavings: income - spent,
      averageDailySpend: spent / days,
      spentDelta: _delta(spent, priorSpent),
      incomeDelta: _delta(income, priorIncome),
      savingsRate: income <= 0 ? null : (income - spent) / income,
    );
  }

  // --- Category breakdown -------------------------------------------------

  static List<CategorySlice> categoryBreakdown({
    required List<Transaction> transactions,
    required ResolvedRange range,
  }) {
    final inWindow = _within(transactions, range);
    final prior = _within(transactions, range.previous);

    final totals = <String, double>{};
    final counts = <String, int>{};
    var grandTotal = 0.0;
    for (final tx in inWindow) {
      if (!tx.isExpense) continue;
      final key = (tx.category ?? 'Other').trim().isEmpty
          ? 'Other'
          : tx.category!.trim();
      totals[key] = (totals[key] ?? 0) + tx.amount;
      counts[key] = (counts[key] ?? 0) + 1;
      grandTotal += tx.amount;
    }
    if (totals.isEmpty) return const [];

    final priorTotals = <String, double>{};
    for (final tx in prior) {
      if (!tx.isExpense) continue;
      final key = (tx.category ?? 'Other').trim().isEmpty
          ? 'Other'
          : tx.category!.trim();
      priorTotals[key] = (priorTotals[key] ?? 0) + tx.amount;
    }

    final slices = totals.entries
        .map((entry) {
          final share = grandTotal <= 0 ? 0.0 : entry.value / grandTotal;
          return CategorySlice(
            category: entry.key,
            total: entry.value,
            share: share,
            transactionCount: counts[entry.key] ?? 0,
            deltaPct: _delta(entry.value, priorTotals[entry.key] ?? 0),
          );
        })
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return slices;
  }

  /// Transactions inside the period that belong to [category].
  static List<Transaction> transactionsForCategory({
    required List<Transaction> transactions,
    required ResolvedRange range,
    required String category,
  }) {
    final key = category.trim().toLowerCase();
    final out = transactions.where((tx) {
      if (!tx.isExpense) return false;
      if (!range.contains(tx.date)) return false;
      final cat = (tx.category ?? 'Other').trim().toLowerCase();
      return cat == key;
    }).toList();
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  /// Last 6 months of spend for [category] — used as the inline mini trend
  /// when a category row is expanded.
  static List<double> categoryMonthlyTrend({
    required List<Transaction> transactions,
    required String category,
    int months = 6,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final key = category.trim().toLowerCase();
    final buckets = List<double>.filled(months, 0.0);
    for (final tx in transactions) {
      if (!tx.isExpense) continue;
      if ((tx.category ?? 'Other').trim().toLowerCase() != key) continue;
      final monthsBack = (clock.year - tx.date.year) * 12 +
          (clock.month - tx.date.month);
      if (monthsBack < 0 || monthsBack >= months) continue;
      buckets[months - 1 - monthsBack] += tx.amount;
    }
    return buckets;
  }

  // --- Income vs expense buckets -----------------------------------------

  /// Bucket transactions into the appropriate granularity for the range.
  /// Short ranges (<= 1 month) use weekly buckets, multi-month ranges
  /// roll up by calendar month.
  static List<PeriodBucket> incomeVsExpenseBuckets({
    required List<Transaction> transactions,
    required ResolvedRange range,
  }) {
    final useWeeks = !_spansMultipleMonths(range);
    return useWeeks
        ? _weeklyBuckets(transactions, range)
        : _monthlyBuckets(transactions, range);
  }

  // --- Subscriptions / recurring -----------------------------------------

  static RecurringSummary recurringSummary({
    required List<Transaction> transactions,
  }) {
    final commitments = <RecurringCommitment>[];
    var subs = 0.0;
    var emi = 0.0;
    final seenSignatures = <String>{};

    for (final tx in transactions) {
      if (!tx.isExpense || !tx.isRecurring) continue;
      // Recurring transactions can appear multiple times in the local cache
      // (one per past occurrence). De-duplicate on a stable signature so the
      // monthly burden isn't double-counted.
      final signature = '${tx.counterpartyName.toLowerCase()}|'
          '${tx.amount.toStringAsFixed(2)}|'
          '${tx.recurrenceFrequency?.name ?? ''}';
      if (!seenSignatures.add(signature)) continue;

      final monthly = _normaliseMonthly(tx);
      final isSub = TransactionSubtypeHelpers.isSubscriptionCategory(
        tx.category,
      );
      final isEmi = TransactionSubtypeHelpers.isEmiCategory(tx.category);
      if (isSub) subs += monthly;
      if (isEmi) emi += monthly;
      commitments.add(
        RecurringCommitment(
          transaction: tx,
          monthlyEquivalent: monthly,
          isSubscription: isSub,
          isEmi: isEmi,
        ),
      );
    }
    commitments.sort(
      (a, b) => b.monthlyEquivalent.compareTo(a.monthlyEquivalent),
    );
    final total = commitments.fold<double>(
      0,
      (sum, c) => sum + c.monthlyEquivalent,
    );
    return RecurringSummary(
      commitments: commitments,
      subscriptionsTotal: subs,
      emiTotal: emi,
      totalMonthly: total,
    );
  }

  // --- Budget snapshots (in-range) ---------------------------------------

  /// Per-budget month-to-date for the *anchor* month of [range]. We always
  /// snap to the latest calendar month in the range so the user sees
  /// "current cycle progress" no matter which range chip they pick.
  static Map<String, double> budgetSpend({
    required List<Transaction> transactions,
    required List<CategoryBudget> budgets,
    required ResolvedRange range,
  }) {
    if (budgets.isEmpty) return const {};
    final anchor = DateTime(range.end.year, range.end.month);
    final nextMonth = DateTime(anchor.year, anchor.month + 1);

    final totals = <String, double>{};
    for (final budget in budgets) {
      final key = budget.categoryName.toLowerCase();
      var spent = 0.0;
      for (final tx in transactions) {
        if (!tx.isExpense) continue;
        if (tx.date.isBefore(anchor) || !tx.date.isBefore(nextMonth)) continue;
        if ((tx.category ?? '').toLowerCase() != key) continue;
        spent += tx.amount;
      }
      totals[budget.categoryName] = spent;
    }
    return totals;
  }

  // --- Long-term trend ---------------------------------------------------

  /// Monthly net (income - expense) for the last [months] calendar months
  /// inclusive, used by the long-term trend chart.
  static List<PeriodBucket> longTermTrend({
    required List<Transaction> transactions,
    int months = 12,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final buckets = <PeriodBucket>[];
    for (var i = months - 1; i >= 0; i--) {
      final start = DateTime(clock.year, clock.month - i, 1);
      final end = DateTime(clock.year, clock.month - i + 1, 1)
          .subtract(const Duration(milliseconds: 1));
      var income = 0.0;
      var expense = 0.0;
      for (final tx in transactions) {
        if (tx.date.isBefore(start) || tx.date.isAfter(end)) continue;
        if (tx.isExpense) {
          expense += tx.amount;
        } else if (tx.isIncome) {
          income += tx.amount;
        }
      }
      buckets.add(
        PeriodBucket(
          label: _shortMonthLabel(start),
          start: start,
          end: end,
          income: income,
          expense: expense,
        ),
      );
    }
    return buckets;
  }

  // --- Behavioural skews -------------------------------------------------

  /// Average expense per weekday (0=Mon … 6=Sun) within [range]. Returns
  /// `null` when fewer than 5 spending days are present so we don't surface
  /// noisy single-day skews.
  static List<double>? weekdayProfile({
    required List<Transaction> transactions,
    required ResolvedRange range,
  }) {
    final totals = List<double>.filled(7, 0.0);
    final counts = List<int>.filled(7, 0);
    var spendingDays = 0;
    for (final tx in _within(transactions, range)) {
      if (!tx.isExpense) continue;
      final idx = tx.date.weekday - 1;
      totals[idx] += tx.amount;
      counts[idx] += 1;
      spendingDays += 1;
    }
    if (spendingDays < 5) return null;
    return [
      for (var i = 0; i < 7; i++)
        counts[i] == 0 ? 0.0 : totals[i] / counts[i],
    ];
  }

  // --- Internals ---------------------------------------------------------

  static List<Transaction> _within(
    List<Transaction> source,
    ResolvedRange range,
  ) {
    return source.where((tx) => range.contains(tx.date)).toList(growable: false);
  }

  static double _sumExpenses(List<Transaction> source) => source
      .where((tx) => tx.isExpense)
      .fold<double>(0, (sum, tx) => sum + tx.amount);

  static double _sumIncome(List<Transaction> source) => source
      .where((tx) => tx.isIncome)
      .fold<double>(0, (sum, tx) => sum + tx.amount);

  static double? _delta(double current, double prior) {
    if (prior <= 0) return null;
    return (current - prior) / prior;
  }

  static bool _spansMultipleMonths(ResolvedRange range) {
    return range.start.year != range.end.year ||
        range.start.month != range.end.month;
  }

  static List<PeriodBucket> _weeklyBuckets(
    List<Transaction> transactions,
    ResolvedRange range,
  ) {
    final buckets = <PeriodBucket>[];
    var cursor = _atStartOfDay(range.start);
    var weekIndex = 1;
    while (!cursor.isAfter(range.end)) {
      final weekEnd = cursor.add(const Duration(days: 6));
      final clampedEnd = weekEnd.isAfter(range.end) ? range.end : weekEnd;
      var income = 0.0;
      var expense = 0.0;
      for (final tx in transactions) {
        if (tx.date.isBefore(cursor) || tx.date.isAfter(clampedEnd)) continue;
        if (tx.isExpense) {
          expense += tx.amount;
        } else if (tx.isIncome) {
          income += tx.amount;
        }
      }
      buckets.add(
        PeriodBucket(
          label: 'W$weekIndex',
          start: cursor,
          end: clampedEnd,
          income: income,
          expense: expense,
        ),
      );
      cursor = cursor.add(const Duration(days: 7));
      weekIndex++;
    }
    return buckets;
  }

  static List<PeriodBucket> _monthlyBuckets(
    List<Transaction> transactions,
    ResolvedRange range,
  ) {
    final buckets = <PeriodBucket>[];
    var cursor = DateTime(range.start.year, range.start.month, 1);
    final endMonth = DateTime(range.end.year, range.end.month, 1);
    while (!cursor.isAfter(endMonth)) {
      final monthEnd = DateTime(cursor.year, cursor.month + 1, 1)
          .subtract(const Duration(milliseconds: 1));
      var income = 0.0;
      var expense = 0.0;
      for (final tx in transactions) {
        if (tx.date.isBefore(cursor) || tx.date.isAfter(monthEnd)) continue;
        if (tx.isExpense) {
          expense += tx.amount;
        } else if (tx.isIncome) {
          income += tx.amount;
        }
      }
      buckets.add(
        PeriodBucket(
          label: _shortMonthLabel(cursor),
          start: cursor,
          end: monthEnd,
          income: income,
          expense: expense,
        ),
      );
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return buckets;
  }

  static double _normaliseMonthly(Transaction tx) {
    switch (tx.recurrenceFrequency) {
      case RecurrenceFrequency.weekly:
        return tx.amount * 4.33;
      case RecurrenceFrequency.daily:
        return tx.amount * 30;
      case RecurrenceFrequency.quarterly:
        return tx.amount / 3;
      case RecurrenceFrequency.yearly:
        return tx.amount / 12;
      case RecurrenceFrequency.monthly:
      case RecurrenceFrequency.custom:
      case null:
        return tx.amount;
    }
  }

  static const _monthShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _shortMonthLabel(DateTime when) => _monthShort[when.month - 1];
}
