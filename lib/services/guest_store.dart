import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/category_budget.dart';
import '../models/expense_category.dart';
import '../models/income_category.dart';
import '../models/recurring_event.dart';
import '../models/transaction.dart';
import '../models/user_settings.dart';
import '../utils/category_style.dart';

/// On-device mirror of [SupabaseService]'s tables for guest mode. Each
/// collection is a JSON-encoded list under its own SharedPreferences key
/// (never one shared blob, so a single write doesn't rewrite everything).
/// IDs are negative and assigned from one shared local counter — unique
/// within a guest session, discarded on migration once the real backend
/// hands out server IDs.
class GuestStore {
  GuestStore._();

  static final GuestStore instance = GuestStore._();

  static const _kTransactions = 'guest.transactions';
  static const _kAccounts = 'guest.accounts';
  static const _kExpenseCategories = 'guest.expense_categories';
  static const _kIncomeCategories = 'guest.income_categories';
  static const _kCategoryBudgets = 'guest.category_budgets';
  static const _kRecurringEvents = 'guest.recurring_events';
  static const _kUserSettings = 'guest.user_settings';
  static const _kNextLocalId = 'guest.next_local_id';

  Future<int> _nextId(SharedPreferences prefs) async {
    final current = prefs.getInt(_kNextLocalId) ?? -1;
    await prefs.setInt(_kNextLocalId, current - 1);
    return current;
  }

  Future<List<Map<String, dynamic>>> _readList(
    SharedPreferences prefs,
    String key,
  ) async {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _writeList(
    SharedPreferences prefs,
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    await prefs.setString(key, jsonEncode(items));
  }

  // --- Transactions ---

  Future<List<Transaction>> fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kTransactions);
    final list = items.map(Transaction.fromMap).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<Transaction> insertTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _nextId(prefs);
    final saved = transaction.copyWith(id: id);
    final items = await _readList(prefs, _kTransactions);
    items.add(saved.toMap());
    await _writeList(prefs, _kTransactions, items);
    return saved;
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kTransactions);
    final idx = items.indexWhere((m) => m['id'] == transaction.id);
    if (idx < 0) {
      throw Exception('Transaction ${transaction.id} not found locally.');
    }
    items[idx] = transaction.toMap();
    await _writeList(prefs, _kTransactions, items);
    return transaction;
  }

  Future<void> deleteTransaction(int transactionId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kTransactions);
    items.removeWhere((m) => m['id'] == transactionId);
    await _writeList(prefs, _kTransactions, items);

    // Mirrors the real schema's FK cascade (recurring_events -> transactions)
    // so a deleted recurring transaction doesn't leave orphaned events.
    final events = await _readList(prefs, _kRecurringEvents);
    events.removeWhere((m) => m['transaction_id'] == transactionId);
    await _writeList(prefs, _kRecurringEvents, events);
  }

  Future<Transaction> setTransactionPaused(
    int transactionId,
    bool paused,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kTransactions);
    final idx = items.indexWhere((m) => m['id'] == transactionId);
    if (idx < 0) {
      throw Exception('Transaction $transactionId not found locally.');
    }
    final updated = Transaction.fromMap(items[idx]).copyWith(isPaused: paused);
    items[idx] = updated.toMap();
    await _writeList(prefs, _kTransactions, items);
    return updated;
  }

  Future<Transaction> setTransactionClosed(
    int transactionId, {
    required bool closed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kTransactions);
    final idx = items.indexWhere((m) => m['id'] == transactionId);
    if (idx < 0) {
      throw Exception('Transaction $transactionId not found locally.');
    }
    final updated = Transaction.fromMap(items[idx]).copyWith(
      closedAt: closed ? DateTime.now().toUtc() : null,
      clearClosedAt: !closed,
    );
    items[idx] = updated.toMap();
    await _writeList(prefs, _kTransactions, items);
    return updated;
  }

  // --- Recurring events ---

  Future<List<RecurringEvent>> fetchRecurringEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kRecurringEvents);
    final list = items.map(RecurringEvent.fromMap).toList()
      ..sort((a, b) => b.occurrenceDate.compareTo(a.occurrenceDate));
    return list;
  }

  /// Upserts by (transaction_id, occurrence_date, event_type) — mirrors the
  /// unique index the real `recurring_events` upsert relies on.
  Future<RecurringEvent> insertRecurringEvent(RecurringEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kRecurringEvents);
    final occurrenceKey = _dateOnly(event.occurrenceDate);
    final idx = items.indexWhere(
      (m) =>
          m['transaction_id'] == event.transactionId &&
          m['occurrence_date'] == occurrenceKey &&
          m['event_type'] == event.eventType.name,
    );

    RecurringEvent saved;
    if (idx >= 0) {
      final existingId = items[idx]['id'] as int;
      saved = event.copyWith(id: existingId);
      items[idx] = saved.toMap();
    } else {
      final id = await _nextId(prefs);
      saved = event.copyWith(id: id);
      items.add(saved.toMap());
    }
    await _writeList(prefs, _kRecurringEvents, items);
    return saved;
  }

  Future<void> deleteRecurringEvent(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kRecurringEvents);
    items.removeWhere((m) => m['id'] == eventId);
    await _writeList(prefs, _kRecurringEvents, items);
  }

  // --- Accounts ---

  Future<List<Account>> fetchAccounts({bool includeArchived = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kAccounts);
    var list = items.map(Account.fromMap).toList();
    if (!includeArchived) {
      list = list.where((a) => !a.isArchived).toList();
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<Account> insertAccount(Account account) async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _nextId(prefs);
    final saved = account.copyWith(id: id);
    final items = await _readList(prefs, _kAccounts);
    items.add(saved.toMap());
    await _writeList(prefs, _kAccounts, items);
    return saved;
  }

  Future<Account> updateAccount(Account account) async {
    if (account.id == null) {
      throw Exception('Cannot update an account without an id.');
    }
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kAccounts);
    final idx = items.indexWhere((m) => m['id'] == account.id);
    if (idx < 0) {
      throw Exception('Account ${account.id} not found locally.');
    }
    items[idx] = account.toMap();
    await _writeList(prefs, _kAccounts, items);
    return account;
  }

  Future<void> deleteAccount(int accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kAccounts);
    items.removeWhere((m) => m['id'] == accountId);
    await _writeList(prefs, _kAccounts, items);
  }

  // --- Category budgets ---

  Future<List<CategoryBudget>> fetchCategoryBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kCategoryBudgets);
    final list = items.map(CategoryBudget.fromMap).toList()
      ..sort((a, b) => a.categoryName.compareTo(b.categoryName));
    return list;
  }

  /// Upserts by category name (case-insensitive) — mirrors the real unique
  /// index on `(user_id, category_name)`.
  Future<CategoryBudget> upsertCategoryBudget(CategoryBudget budget) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kCategoryBudgets);
    final key = budget.categoryName.trim().toLowerCase();
    final idx = items.indexWhere(
      (m) => (m['category_name'] as String).trim().toLowerCase() == key,
    );

    CategoryBudget saved;
    if (idx >= 0) {
      final existingId = items[idx]['id'] as int;
      saved = budget.copyWith(id: existingId);
      items[idx] = saved.toMap();
    } else {
      final id = await _nextId(prefs);
      saved = budget.copyWith(id: id);
      items.add(saved.toMap());
    }
    await _writeList(prefs, _kCategoryBudgets, items);
    return saved;
  }

  Future<void> deleteCategoryBudget(int budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kCategoryBudgets);
    items.removeWhere((m) => m['id'] == budgetId);
    await _writeList(prefs, _kCategoryBudgets, items);
  }

  // --- Onboarding wizard status (guest's own flag, deliberately separate
  // from UserSettings.preferences — see docs/designs/post-login-onboarding.md,
  // Open Question #2) ---

  static const _kOnboardingComplete = 'guest.onboarding_complete';

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingComplete, true);
  }

  // --- User settings (single row, no server round trip) ---

  Future<UserSettings?> fetchUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserSettings);
    if (raw == null) return null;
    return UserSettings.fromMap(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<UserSettings> upsertUserSettings(
    String defaultCurrencyCode, {
    Map<String, dynamic>? preferences,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> resolvedPrefs;
    if (preferences != null) {
      resolvedPrefs = Map<String, dynamic>.from(preferences);
    } else {
      final existing = await fetchUserSettings();
      resolvedPrefs = existing?.preferences ?? {};
    }

    final settings = UserSettings(
      userId: 'guest',
      defaultCurrencyCode: defaultCurrencyCode,
      preferences: resolvedPrefs,
      updatedAt: DateTime.now().toUtc(),
    );
    await prefs.setString(_kUserSettings, jsonEncode(settings.toMap()));
    return settings;
  }

  // --- Expense categories ---

  Future<List<ExpenseCategory>> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kExpenseCategories);
    final list = items.map(ExpenseCategory.fromMap).toList()
      ..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        return bySort != 0 ? bySort : a.name.compareTo(b.name);
      });
    return list;
  }

  Future<List<ExpenseCategory>> ensureDefaultCategories() async {
    final prefs = await SharedPreferences.getInstance();
    var existing = await fetchCategories();
    final existingNames = existing.map((c) => c.name.trim().toLowerCase()).toSet();

    final items = await _readList(prefs, _kExpenseCategories);
    var changed = false;
    for (final entry in DefaultCategories.seeds.asMap().entries) {
      final seed = entry.value;
      if (existingNames.contains(seed.name.toLowerCase())) continue;
      final id = await _nextId(prefs);
      items.add(
        ExpenseCategory(
          id: id,
          name: seed.name,
          iconKey: seed.iconKey,
          sortOrder: entry.key,
          isDefault: true,
        ).toMap(),
      );
      changed = true;
    }

    if (changed) {
      await _writeList(prefs, _kExpenseCategories, items);
      existing = await fetchCategories();
    }
    return existing;
  }

  Future<ExpenseCategory> insertCategory({
    required String name,
    required String iconKey,
    required int sortOrder,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _nextId(prefs);
    final saved = ExpenseCategory(
      id: id,
      name: name,
      iconKey: iconKey,
      sortOrder: sortOrder,
    );
    final items = await _readList(prefs, _kExpenseCategories);
    items.add(saved.toMap());
    await _writeList(prefs, _kExpenseCategories, items);
    return saved;
  }

  Future<void> deleteCategory(int categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kExpenseCategories);
    items.removeWhere(
      (m) => m['id'] == categoryId && m['is_default'] != true,
    );
    await _writeList(prefs, _kExpenseCategories, items);
  }

  // --- Income categories (mirrors expense categories) ---

  Future<List<IncomeCategory>> fetchIncomeCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kIncomeCategories);
    final list = items.map(IncomeCategory.fromMap).toList()
      ..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        return bySort != 0 ? bySort : a.name.compareTo(b.name);
      });
    return list;
  }

  Future<List<IncomeCategory>> ensureDefaultIncomeCategories() async {
    final prefs = await SharedPreferences.getInstance();
    var existing = await fetchIncomeCategories();
    final existingNames = existing.map((c) => c.name.trim().toLowerCase()).toSet();

    final items = await _readList(prefs, _kIncomeCategories);
    var changed = false;
    for (final entry in DefaultIncomeCategories.seeds.asMap().entries) {
      final seed = entry.value;
      if (existingNames.contains(seed.name.toLowerCase())) continue;
      final id = await _nextId(prefs);
      items.add(
        IncomeCategory(
          id: id,
          name: seed.name,
          iconKey: seed.iconKey,
          sortOrder: entry.key,
          isDefault: true,
        ).toMap(),
      );
      changed = true;
    }

    if (changed) {
      await _writeList(prefs, _kIncomeCategories, items);
      existing = await fetchIncomeCategories();
    }
    return existing;
  }

  Future<IncomeCategory> insertIncomeCategory({
    required String name,
    required String iconKey,
    required int sortOrder,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _nextId(prefs);
    final saved = IncomeCategory(
      id: id,
      name: name,
      iconKey: iconKey,
      sortOrder: sortOrder,
    );
    final items = await _readList(prefs, _kIncomeCategories);
    items.add(saved.toMap());
    await _writeList(prefs, _kIncomeCategories, items);
    return saved;
  }

  Future<void> deleteIncomeCategory(int categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readList(prefs, _kIncomeCategories);
    items.removeWhere(
      (m) => m['id'] == categoryId && m['is_default'] != true,
    );
    await _writeList(prefs, _kIncomeCategories, items);
  }

  // --- Whole-store operations ---

  /// Mirrors `SupabaseService.resetUserData()` — wipes everything except
  /// `user_settings`. Used by guest "Reset My Account".
  Future<void> resetUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kTransactions),
      prefs.remove(_kRecurringEvents),
      prefs.remove(_kAccounts),
      prefs.remove(_kCategoryBudgets),
      prefs.remove(_kExpenseCategories),
      prefs.remove(_kIncomeCategories),
    ]);
  }

  /// Full wipe, including `user_settings` and the local ID counter — used
  /// once a migration into a real account fully succeeds, or the user
  /// explicitly discards their guest data.
  Future<void> clearEverything() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kTransactions),
      prefs.remove(_kRecurringEvents),
      prefs.remove(_kAccounts),
      prefs.remove(_kCategoryBudgets),
      prefs.remove(_kExpenseCategories),
      prefs.remove(_kIncomeCategories),
      prefs.remove(_kUserSettings),
      prefs.remove(_kNextLocalId),
    ]);
  }

  /// True when the guest has entered anything worth offering to migrate —
  /// deliberately excludes the always-present seeded default categories, so
  /// a guest who only ever saw the empty state doesn't trigger a migration
  /// prompt or a "leftover data" Settings entry.
  Future<bool> hasMigratableData() async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await _readList(prefs, _kTransactions);
    if (transactions.isNotEmpty) return true;
    final accounts = await _readList(prefs, _kAccounts);
    if (accounts.isNotEmpty) return true;
    final budgets = await _readList(prefs, _kCategoryBudgets);
    if (budgets.isNotEmpty) return true;
    final events = await _readList(prefs, _kRecurringEvents);
    if (events.isNotEmpty) return true;
    final categories = await _readList(prefs, _kExpenseCategories);
    if (categories.any((m) => m['is_default'] != true)) return true;
    final incomeCategories = await _readList(prefs, _kIncomeCategories);
    if (incomeCategories.any((m) => m['is_default'] != true)) return true;
    return false;
  }

  static String _dateOnly(DateTime when) {
    final y = when.year.toString().padLeft(4, '0');
    final m = when.month.toString().padLeft(2, '0');
    final d = when.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
