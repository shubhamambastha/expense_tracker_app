import '../models/account.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import 'recurrence_normalization.dart';
import 'transaction_subtype_helpers.dart';

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

  /// Sum of income transactions dated `now`'s calendar day.
  static double todayIncome(
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    return transactions
        .where((t) => t.isIncome && _isSameDay(t.date, clock))
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Net cash flow for `now`'s calendar day (income minus expenses).
  static double todayBalance(
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    return todayIncome(transactions, now: now) -
        todaySpend(transactions, now: now);
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

  /// Sum of income transactions in `now`'s current month.
  static double monthIncome(
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    return transactions
        .where((t) => t.isIncome && _isSameMonth(t.date, clock))
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

  /// True when a recurring expense schedule is active at any point during
  /// the month spanning [monthStart]..[monthEnd] (not paused, not closed,
  /// started on/before the month ends, and hasn't ended before it starts).
  static bool _isActiveRecurringExpenseInMonth(
    Transaction t,
    DateTime monthStart,
    DateTime monthEnd,
  ) {
    if (!t.isRecurring || !t.isExpense || t.isPaused || t.isClosed) {
      return false;
    }
    final start = t.recurrenceStartDate ?? t.date;
    if (start.isAfter(monthEnd)) return false;
    final end = t.recurrenceEndDate;
    if (end != null && end.isBefore(monthStart)) return false;
    return true;
  }

  /// Projected total of active recurring expenses (EMIs, subscriptions,
  /// loans, etc.) for `now`'s calendar month, normalised to a monthly figure
  /// regardless of each schedule's actual frequency.
  static double monthlyRecurringExpenseTotal(
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final monthStart = DateTime(clock.year, clock.month, 1);
    final monthEnd = DateTime(clock.year, clock.month + 1, 0);
    return transactions
        .where(
          (t) => _isActiveRecurringExpenseInMonth(t, monthStart, monthEnd),
        )
        .fold<double>(0.0, (sum, t) => sum + monthlyEquivalent(t));
  }

  /// Sum of expense transactions in `now`'s current month that are NOT
  /// already accounted for by [monthlyRecurringExpenseTotal] — excludes both
  /// recurring template rows and the one-time "mark paid" clones the
  /// Recurring Payments Manager inserts for EMI/Subscription categories (see
  /// `RecurringPaymentsPage._markPaid`), so a recurring commitment is never
  /// subtracted twice from the discretionary budget.
  static double discretionaryMonthSpend(
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    return transactions
        .where(
          (t) =>
              t.isExpense &&
              _isSameMonth(t.date, clock) &&
              !t.isRecurring &&
              !TransactionSubtypeHelpers.isEmiCategory(t.category) &&
              !TransactionSubtypeHelpers.isSubscriptionCategory(t.category),
        )
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// "How much can I spend today" — this month's discretionary budget
  /// (income minus active recurring commitments) accrued day by day through
  /// the month, minus non-recurring spending so far. Resets each calendar
  /// month; can go negative on an overspending month.
  static double spendableToday(
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final income = monthIncome(transactions, now: clock);
    final recurring = monthlyRecurringExpenseTotal(transactions, now: clock);
    final monthlyDiscretionary = income - recurring;

    final daysInMonth = DateTime(clock.year, clock.month + 1, 0).day;
    final dailyAllowance = monthlyDiscretionary / daysInMonth;
    final accrued = dailyAllowance * clock.day;

    final spent = discretionaryMonthSpend(transactions, now: clock);
    return accrued - spent;
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

  /// Net worth across every account: sum of each account's running balance.
  static double totalBalance(
    List<Account> accounts,
    List<Transaction> transactions,
  ) {
    return accounts.fold<double>(
      0.0,
      (sum, account) => sum + accountBalance(account, transactions),
    );
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
