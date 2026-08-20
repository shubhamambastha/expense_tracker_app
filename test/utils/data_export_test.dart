import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/models/account.dart';
import 'package:expense_tracker_app/models/category_budget.dart';
import 'package:expense_tracker_app/models/expense.dart';
import 'package:expense_tracker_app/models/transaction.dart';
import 'package:expense_tracker_app/models/transaction_draft.dart';
import 'package:expense_tracker_app/utils/data_export.dart';

void main() {
  group('transactionsToCsv', () {
    test('empty list produces header-only output', () {
      final csv = transactionsToCsv(const []);
      expect(csv.trim().split('\n'), hasLength(1));
      expect(csv, startsWith('date,kind,amount,currency'));
    });

    test('serializes fields in order', () {
      final tx = Transaction(
        amount: 12.5,
        counterpartyName: 'Coffee Shop',
        date: DateTime(2027, 1, 5),
        kind: TransactionKind.expense,
        category: 'Food',
        note: 'latte',
      );
      final csv = transactionsToCsv([tx]);
      final rows = csv.trim().split('\n');
      expect(rows, hasLength(2));
      expect(rows[1], contains('expense'));
      expect(rows[1], contains('12.5'));
      expect(rows[1], contains('Coffee Shop'));
      expect(rows[1], contains('Food'));
      expect(rows[1], contains('latte'));
    });

    test('quotes fields containing commas and escapes embedded quotes', () {
      final tx = Transaction(
        amount: 5,
        counterpartyName: 'Joe\'s "Diner", Downtown',
        date: DateTime(2027, 1, 1),
      );
      final csv = transactionsToCsv([tx]);
      expect(csv, contains('"Joe\'s ""Diner"", Downtown"'));
    });
  });

  group('accountsToCsv', () {
    test('empty list produces header-only output', () {
      final csv = accountsToCsv(const []);
      expect(csv.trim().split('\n'), hasLength(1));
    });

    test('serializes account fields', () {
      final account = Account(
        name: 'HDFC Savings',
        type: AccountType.bank,
        openingBalance: 1000,
        providerName: 'HDFC',
      );
      final csv = accountsToCsv([account]);
      expect(csv, contains('HDFC Savings'));
      expect(csv, contains('bank'));
      expect(csv, contains('1000'));
      expect(csv, contains('HDFC'));
    });
  });

  group('categoryBudgetsToCsv', () {
    test('empty list produces header-only output', () {
      final csv = categoryBudgetsToCsv(const []);
      expect(csv.trim().split('\n'), hasLength(1));
    });

    test('serializes budget fields', () {
      final budget = CategoryBudget(categoryName: 'Groceries', monthlyLimit: 200);
      final csv = categoryBudgetsToCsv([budget]);
      expect(csv, contains('Groceries'));
      expect(csv, contains('200'));
    });
  });
}
