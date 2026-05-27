import '../models/account.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';

/// Pure aggregation helpers shared by every dashboard section. Kept out of
/// widgets so they can be unit-tested and swapped with cached/computed
/// providers in the future without UI changes.
class DashboardAggregations {
  DashboardAggregations._();

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Sum of expense transactions dated `now`'s calendar day.
  static double todaySpend(
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    return transactions
        .where((t) => t.isExpense && _isSameDay(t.date, clock))
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Sum of expense transactions in `now`'s current month.
  static double monthSpend(
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    return transactions
        .where((t) => t.isExpense && _isSameMonth(t.date, clock))
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Sum of expense transactions for `categoryName` in the current month
  /// (case-insensitive match).
  static double categoryMonthSpend(
    List<Transaction> transactions,
    String categoryName, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final key = categoryName.trim().toLowerCase();
    return transactions
        .where(
          (t) =>
              t.isExpense &&
              _isSameMonth(t.date, clock) &&
              (t.category ?? '').trim().toLowerCase() == key,
        )
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Days from `now` through the last day of the current month, inclusive.
  /// Returns 1 on the last day so we never divide by zero in [safeDailySpend].
  static int daysRemainingInMonth({DateTime? now}) {
    final clock = now ?? DateTime.now();
    final lastDay = DateTime(clock.year, clock.month + 1, 0).day;
    return (lastDay - clock.day + 1).clamp(1, 31);
  }

  /// Recommended daily spend = remaining budget divided by remaining days.
  /// Returns `null` when [monthlyLimit] is null or already exceeded.
  static double? safeDailySpend({
    required double? monthlyLimit,
    required double monthSpent,
    required int daysRemaining,
  }) {
    if (monthlyLimit == null) return null;
    final remaining = monthlyLimit - monthSpent;
    if (remaining <= 0) return 0;
    if (daysRemaining <= 0) return remaining;
    return remaining / daysRemaining;
  }

  /// Running balance for [account]: opening balance + incoming - outgoing.
  /// Includes transfers into the account and out of it.
  static double accountBalance(
    Account account,
    List<Transaction> transactions,
  ) {
    if (account.id == null) return account.openingBalance;

    var balance = account.openingBalance;
    for (final tx in transactions) {
      if (tx.kind == TransactionKind.expense && tx.accountId == account.id) {
        balance -= tx.amount;
      } else if (tx.kind == TransactionKind.income &&
          tx.accountId == account.id) {
        balance += tx.amount;
      } else if (tx.kind == TransactionKind.transfer) {
        if (tx.accountId == account.id) balance -= tx.amount;
        if (tx.transferToAccountId == account.id) balance += tx.amount;
      }
    }
    return balance;
  }

  /// Used amount on a credit card = sum of expenses charged to it for the
  /// current statement window. We use a simple month-to-date proxy here
  /// (good enough for the home glance view; full statement logic lives in
  /// the account screen later).
  static double creditCardUsed(
    Account account,
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    if (!account.isCreditCard || account.id == null) return 0;
    final clock = now ?? DateTime.now();
    return transactions
        .where(
          (t) =>
              t.isExpense &&
              t.accountId == account.id &&
              _isSameMonth(t.date, clock),
        )
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }
}
