import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker_app/models/account.dart';
import 'package:expense_tracker_app/models/category_budget.dart';
import 'package:expense_tracker_app/models/expense.dart' show AccountType;
import 'package:expense_tracker_app/models/recurring_event.dart';
import 'package:expense_tracker_app/models/transaction.dart';
import 'package:expense_tracker_app/services/guest_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GuestStore transactions', () {
    test('inserted transactions get unique negative local ids', () async {
      final a = await GuestStore.instance.insertTransaction(
        Transaction(amount: 10, counterpartyName: 'Coffee', date: DateTime(2026, 1, 1)),
      );
      final b = await GuestStore.instance.insertTransaction(
        Transaction(amount: 20, counterpartyName: 'Lunch', date: DateTime(2026, 1, 2)),
      );

      expect(a.id, isNotNull);
      expect(b.id, isNotNull);
      expect(a.id, lessThan(0));
      expect(b.id, lessThan(0));
      expect(a.id, isNot(equals(b.id)));
    });

    test('fetchTransactions returns newest date first', () async {
      await GuestStore.instance.insertTransaction(
        Transaction(amount: 10, counterpartyName: 'Old', date: DateTime(2026, 1, 1)),
      );
      await GuestStore.instance.insertTransaction(
        Transaction(amount: 20, counterpartyName: 'New', date: DateTime(2026, 3, 1)),
      );

      final all = await GuestStore.instance.fetchTransactions();
      expect(all, hasLength(2));
      expect(all.first.counterpartyName, 'New');
      expect(all.last.counterpartyName, 'Old');
    });

    test('deleteTransaction also removes its recurring events', () async {
      final tx = await GuestStore.instance.insertTransaction(
        Transaction(
          amount: 500,
          counterpartyName: 'Netflix',
          date: DateTime(2026, 1, 1),
          isRecurring: true,
        ),
      );
      await GuestStore.instance.insertRecurringEvent(
        RecurringEvent(
          transactionId: tx.id!,
          occurrenceDate: DateTime(2026, 1, 1),
          eventType: RecurringEventType.paid,
        ),
      );

      await GuestStore.instance.deleteTransaction(tx.id!);

      expect(await GuestStore.instance.fetchTransactions(), isEmpty);
      expect(await GuestStore.instance.fetchRecurringEvents(), isEmpty);
    });
  });

  group('GuestStore.insertRecurringEvent upsert', () {
    test('same (transactionId, occurrenceDate, eventType) replaces rather than duplicates', () async {
      final occurrence = DateTime(2026, 5, 1);
      final first = await GuestStore.instance.insertRecurringEvent(
        RecurringEvent(
          transactionId: 1,
          occurrenceDate: occurrence,
          eventType: RecurringEventType.snoozed,
        ),
      );
      final second = await GuestStore.instance.insertRecurringEvent(
        RecurringEvent(
          transactionId: 1,
          occurrenceDate: occurrence,
          eventType: RecurringEventType.snoozed,
          snoozeUntil: DateTime(2026, 5, 3),
        ),
      );

      final all = await GuestStore.instance.fetchRecurringEvents();
      expect(all, hasLength(1));
      expect(second.id, first.id);
      expect(all.single.snoozeUntil, DateTime(2026, 5, 3));
    });
  });

  group('GuestStore.upsertCategoryBudget', () {
    test('same category name (any case) replaces rather than duplicates', () async {
      await GuestStore.instance.upsertCategoryBudget(
        const CategoryBudget(categoryName: 'Food', monthlyLimit: 100),
      );
      await GuestStore.instance.upsertCategoryBudget(
        const CategoryBudget(categoryName: 'FOOD', monthlyLimit: 150),
      );

      final all = await GuestStore.instance.fetchCategoryBudgets();
      expect(all, hasLength(1));
      expect(all.single.monthlyLimit, 150);
    });
  });

  group('GuestStore default categories', () {
    test('ensureDefaultCategories seeds once and is idempotent', () async {
      final first = await GuestStore.instance.ensureDefaultCategories();
      final second = await GuestStore.instance.ensureDefaultCategories();

      expect(first, isNotEmpty);
      expect(second.length, first.length);
    });

    test('deleteCategory cannot remove a default category', () async {
      final defaults = await GuestStore.instance.ensureDefaultCategories();
      final defaultCategory = defaults.first;

      await GuestStore.instance.deleteCategory(defaultCategory.id!);

      final remaining = await GuestStore.instance.fetchCategories();
      expect(remaining.any((c) => c.id == defaultCategory.id), isTrue);
    });

    test('deleteCategory removes a custom (non-default) category', () async {
      final custom = await GuestStore.instance.insertCategory(
        name: 'Custom',
        iconKey: 'category_rounded',
        sortOrder: 99,
      );

      await GuestStore.instance.deleteCategory(custom.id!);

      final remaining = await GuestStore.instance.fetchCategories();
      expect(remaining.any((c) => c.id == custom.id), isFalse);
    });
  });

  group('GuestStore.hasMigratableData', () {
    test('false when only default categories exist', () async {
      await GuestStore.instance.ensureDefaultCategories();
      await GuestStore.instance.ensureDefaultIncomeCategories();

      expect(await GuestStore.instance.hasMigratableData(), isFalse);
    });

    test('true once a transaction is added', () async {
      await GuestStore.instance.ensureDefaultCategories();
      await GuestStore.instance.insertTransaction(
        Transaction(amount: 5, counterpartyName: 'Snack', date: DateTime(2026, 1, 1)),
      );

      expect(await GuestStore.instance.hasMigratableData(), isTrue);
    });
  });

  group('GuestStore.resetUserData / clearEverything', () {
    test('resetUserData wipes transactions but keeps user settings', () async {
      await GuestStore.instance.insertTransaction(
        Transaction(amount: 5, counterpartyName: 'Snack', date: DateTime(2026, 1, 1)),
      );
      await GuestStore.instance.upsertUserSettings('USD');

      await GuestStore.instance.resetUserData();

      expect(await GuestStore.instance.fetchTransactions(), isEmpty);
      expect(await GuestStore.instance.fetchUserSettings(), isNotNull);
    });

    test('clearEverything wipes user settings too', () async {
      await GuestStore.instance.upsertUserSettings('USD');

      await GuestStore.instance.clearEverything();

      expect(await GuestStore.instance.fetchUserSettings(), isNull);
    });
  });

  group('GuestStore accounts', () {
    test('updateAccount preserves id, insertAccount assigns one', () async {
      final saved = await GuestStore.instance.insertAccount(
        const Account(name: 'Checking', type: AccountType.bank),
      );
      expect(saved.id, isNotNull);

      final updated = await GuestStore.instance.updateAccount(
        saved.copyWith(name: 'Primary Checking'),
      );
      expect(updated.id, saved.id);

      final all = await GuestStore.instance.fetchAccounts();
      expect(all.single.name, 'Primary Checking');
    });
  });
}
