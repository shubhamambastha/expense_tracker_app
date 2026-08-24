import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/models/transaction.dart';
import 'package:expense_tracker_app/models/transaction_draft.dart';
import 'package:expense_tracker_app/utils/dashboard_aggregations.dart';

Transaction _income(
  double amount,
  DateTime date, {
  bool isRecurring = false,
  bool isPaused = false,
  DateTime? closedAt,
  RecurrenceFrequency? recurrenceFrequency,
  DateTime? recurrenceStartDate,
  DateTime? recurrenceEndDate,
}) => Transaction(
  amount: amount,
  counterpartyName: 'Salary',
  date: date,
  kind: TransactionKind.income,
  isRecurring: isRecurring,
  isPaused: isPaused,
  closedAt: closedAt,
  recurrenceFrequency: recurrenceFrequency,
  recurrenceStartDate: recurrenceStartDate,
  recurrenceEndDate: recurrenceEndDate,
);

Transaction _expense(
  double amount,
  DateTime date, {
  String? category,
  bool isRecurring = false,
  bool isPaused = false,
  DateTime? closedAt,
  RecurrenceFrequency? recurrenceFrequency,
  DateTime? recurrenceStartDate,
  DateTime? recurrenceEndDate,
}) => Transaction(
  amount: amount,
  counterpartyName: 'Expense',
  date: date,
  kind: TransactionKind.expense,
  category: category,
  isRecurring: isRecurring,
  isPaused: isPaused,
  closedAt: closedAt,
  recurrenceFrequency: recurrenceFrequency,
  recurrenceStartDate: recurrenceStartDate,
  recurrenceEndDate: recurrenceEndDate,
);

void main() {
  group('monthlyRecurringExpenseTotal', () {
    test('normalises frequencies to a monthly equivalent', () {
      final now = DateTime(2027, 1, 15);
      final transactions = [
        _expense(
          100,
          DateTime(2027, 1, 1),
          category: 'EMI',
          isRecurring: true,
          recurrenceFrequency: RecurrenceFrequency.monthly,
          recurrenceStartDate: DateTime(2027, 1, 1),
        ),
        _expense(
          70,
          DateTime(2027, 1, 1),
          category: 'Subscription',
          isRecurring: true,
          recurrenceFrequency: RecurrenceFrequency.weekly,
          recurrenceStartDate: DateTime(2027, 1, 1),
        ),
      ];
      final total = DashboardAggregations.monthlyRecurringExpenseTotal(
        transactions,
        now: now,
      );
      expect(total, closeTo(100 + 70 * 4.33, 0.001));
    });

    test('excludes paused and closed schedules', () {
      final now = DateTime(2027, 1, 15);
      final transactions = [
        _expense(
          100,
          DateTime(2027, 1, 1),
          isRecurring: true,
          isPaused: true,
          recurrenceFrequency: RecurrenceFrequency.monthly,
          recurrenceStartDate: DateTime(2027, 1, 1),
        ),
        _expense(
          50,
          DateTime(2027, 1, 1),
          isRecurring: true,
          closedAt: DateTime(2027, 1, 5),
          recurrenceFrequency: RecurrenceFrequency.monthly,
          recurrenceStartDate: DateTime(2027, 1, 1),
        ),
      ];
      expect(
        DashboardAggregations.monthlyRecurringExpenseTotal(
          transactions,
          now: now,
        ),
        0,
      );
    });

    test('excludes schedules that have ended before this month', () {
      final now = DateTime(2027, 3, 1);
      final transactions = [
        _expense(
          100,
          DateTime(2027, 1, 1),
          isRecurring: true,
          recurrenceFrequency: RecurrenceFrequency.monthly,
          recurrenceStartDate: DateTime(2027, 1, 1),
          recurrenceEndDate: DateTime(2027, 2, 1),
        ),
      ];
      expect(
        DashboardAggregations.monthlyRecurringExpenseTotal(
          transactions,
          now: now,
        ),
        0,
      );
    });
  });

  group('monthIncome / monthlyRecurringIncomeTotal / totalMonthIncome', () {
    test(
      'CRITICAL REGRESSION: a recurring income transaction is not '
      'double-counted in its own creation month',
      () {
        final now = DateTime(2027, 1, 15);
        final transactions = [
          _income(
            5000,
            DateTime(2027, 1, 1),
            isRecurring: true,
            recurrenceFrequency: RecurrenceFrequency.monthly,
            recurrenceStartDate: DateTime(2027, 1, 1),
          ),
        ];

        // monthIncome alone must exclude the recurring row entirely — it's
        // accounted for by the projection instead.
        expect(
          DashboardAggregations.monthIncome(transactions, now: now),
          0,
        );
        expect(
          DashboardAggregations.monthlyRecurringIncomeTotal(
            transactions,
            now: now,
          ),
          5000,
        );
        // The combined figure every dashboard surface should use counts it
        // exactly once.
        expect(
          DashboardAggregations.totalMonthIncome(transactions, now: now),
          5000,
        );
      },
    );

    test('non-recurring income is counted normally, unaffected', () {
      final now = DateTime(2027, 1, 15);
      final transactions = [_income(1200, DateTime(2027, 1, 10))];
      expect(
        DashboardAggregations.monthIncome(transactions, now: now),
        1200,
      );
      expect(
        DashboardAggregations.monthlyRecurringIncomeTotal(
          transactions,
          now: now,
        ),
        0,
      );
      expect(
        DashboardAggregations.totalMonthIncome(transactions, now: now),
        1200,
      );
    });

    test(
      'recurring income still projects correctly in a later month, not '
      'just the creation month',
      () {
        final createdIn = DateTime(2027, 1, 1);
        final laterMonth = DateTime(2027, 3, 15);
        final transactions = [
          _income(
            5000,
            createdIn,
            isRecurring: true,
            recurrenceFrequency: RecurrenceFrequency.monthly,
            recurrenceStartDate: createdIn,
          ),
        ];
        expect(
          DashboardAggregations.totalMonthIncome(
            transactions,
            now: laterMonth,
          ),
          5000,
        );
      },
    );

    test('mixed recurring + non-recurring income sums both, once each', () {
      final now = DateTime(2027, 1, 15);
      final transactions = [
        _income(
          5000,
          DateTime(2027, 1, 1),
          isRecurring: true,
          recurrenceFrequency: RecurrenceFrequency.monthly,
          recurrenceStartDate: DateTime(2027, 1, 1),
        ),
        _income(300, DateTime(2027, 1, 12)), // one-off freelance payment
      ];
      expect(
        DashboardAggregations.totalMonthIncome(transactions, now: now),
        5300,
      );
    });
  });

  group('discretionaryMonthSpend', () {
    test('excludes recurring template rows', () {
      final now = DateTime(2027, 1, 15);
      final transactions = [
        _expense(
          190,
          DateTime(2027, 1, 1),
          category: 'EMI',
          isRecurring: true,
          recurrenceFrequency: RecurrenceFrequency.monthly,
        ),
        _expense(20, DateTime(2027, 1, 10)),
      ];
      expect(
        DashboardAggregations.discretionaryMonthSpend(transactions, now: now),
        20,
      );
    });

    test(
      'excludes mark-paid clones by category (RecurringPaymentsPage._markPaid)',
      () {
        final now = DateTime(2027, 1, 15);
        // Mirrors the clone RecurringPaymentsPage._markPaid inserts: same
        // category as the recurring template, but isRecurring flipped false.
        final transactions = [
          _expense(190, DateTime(2027, 1, 15), category: 'EMI'),
          _expense(15, DateTime(2027, 1, 15)),
        ];
        expect(
          DashboardAggregations.discretionaryMonthSpend(
            transactions,
            now: now,
          ),
          15,
        );
      },
    );
  });

  group('spendableToday', () {
    test('matches the worked example: income 500, recurring 190, 31 days', () {
      final transactions = [
        _income(500, DateTime(2027, 1, 1)),
        _expense(
          190,
          DateTime(2027, 1, 1),
          category: 'EMI',
          isRecurring: true,
          recurrenceFrequency: RecurrenceFrequency.monthly,
          recurrenceStartDate: DateTime(2027, 1, 1),
        ),
      ];

      final day1 = DashboardAggregations.spendableToday(
        transactions,
        now: DateTime(2027, 1, 1),
      );
      final day2 = DashboardAggregations.spendableToday(
        transactions,
        now: DateTime(2027, 1, 2),
      );
      final day31 = DashboardAggregations.spendableToday(
        transactions,
        now: DateTime(2027, 1, 31),
      );

      expect(day1, closeTo(10, 0.001));
      expect(day2, closeTo(20, 0.001));
      expect(day31, closeTo(310, 0.001));
    });

    test('goes negative when discretionary spend exceeds the accrued amount', () {
      final transactions = [
        _income(500, DateTime(2027, 1, 1)),
        _expense(
          190,
          DateTime(2027, 1, 1),
          category: 'EMI',
          isRecurring: true,
          recurrenceFrequency: RecurrenceFrequency.monthly,
          recurrenceStartDate: DateTime(2027, 1, 1),
        ),
        _expense(50, DateTime(2027, 1, 1)),
      ];

      final result = DashboardAggregations.spendableToday(
        transactions,
        now: DateTime(2027, 1, 1),
      );
      expect(result, closeTo(10 - 50, 0.001));
      expect(result, lessThan(0));
    });
  });
}
