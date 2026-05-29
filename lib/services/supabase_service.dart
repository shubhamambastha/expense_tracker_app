import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_config.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import '../models/account.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/recurring_event.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import '../models/expense_category.dart';
import '../models/income_category.dart';
import '../models/user_settings.dart';
import '../utils/category_style.dart';

class SupabaseService {
  SupabaseService._();

  // Supabase URL and anon key are read from environment variables.
  // Provide them via compile-time defines.
  static Future<void> init() async {
    if (!AppConfig.hasSupabase) {
      throw Exception(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Provide via --dart-define',
      );
    }

    await AuthService.instance.init();

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      debug: kDebugMode,
      accessToken: () async {
        if (!await AuthService.instance.hasValidCredentials()) {
          return null;
        }
        final creds = await AuthService.instance.credentials();
        final idToken = creds.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw Exception(
            'Auth0 ID token is missing. Sign in again via Continue with Auth0.',
          );
        }
        return idToken;
      },
    );
  }

  /// Auth0 `sub` — scopes all Supabase rows for the signed-in user.
  static String requireUserId([String? message]) {
    final userId = AuthService.instance.currentSession?.userId;
    if (userId == null || userId.isEmpty) {
      throw Exception(message ?? AppConstants.errorNotSignedIn);
    }
    return userId;
  }

  static Future<List<Transaction>> fetchTransactions() async {
    final userId = requireUserId();

    final data = await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return (data as List<dynamic>)
        .map((item) => Transaction.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Expense-only fetch kept for callers not yet on [fetchTransactions].
  static Future<List<Expense>> fetchExpenses() async {
    final all = await fetchTransactions();
    return all
        .where((t) => t.kind == TransactionKind.expense)
        .map(_expenseFromTransaction)
        .toList();
  }

  static Expense _expenseFromTransaction(Transaction t) {
    return Expense(
      id: t.id,
      userId: t.userId,
      name: t.counterpartyName,
      category: t.category ?? 'Other',
      date: t.date,
      type: t.isRecurring ? ExpenseType.recurring : ExpenseType.oneTime,
      amount: t.amount,
      accountId: t.accountId,
      endDate: t.recurrenceEndDate,
    );
  }

  static Future<Transaction> insertTransaction(Transaction transaction) async {
    final userId = requireUserId();

    final payload = transaction.toMap()..['user_id'] = userId;
    payload.remove('id');
    final data = await Supabase.instance.client
        .from('transactions')
        .insert(payload)
        .select()
        .single();

    return Transaction.fromMap(data);
  }

  static Future<Transaction> updateTransaction(Transaction transaction) async {
    final userId = requireUserId();

    final payload = transaction.toMap()
      ..remove('user_id')
      ..remove('id');
    final data = await Supabase.instance.client
        .from('transactions')
        .update(payload)
        .eq('id', transaction.id!)
        .eq('user_id', userId)
        .select()
        .single();

    return Transaction.fromMap(data);
  }

  static Future<void> deleteTransaction(int transactionId) async {
    final userId = requireUserId();

    await Supabase.instance.client
        .from('transactions')
        .delete()
        .eq('id', transactionId)
        .eq('user_id', userId);
  }

  /// Toggles the `is_paused` flag on a recurring transaction without losing
  /// any of its schedule metadata. Used by the Recurring Payments Manager
  /// "Pause / Resume" action.
  static Future<Transaction> setTransactionPaused(
    int transactionId,
    bool paused,
  ) async {
    final userId = requireUserId();

    final data = await Supabase.instance.client
        .from('transactions')
        .update({'is_paused': paused})
        .eq('id', transactionId)
        .eq('user_id', userId)
        .select()
        .single();

    return Transaction.fromMap(data);
  }

  /// Terminates (or re-opens via Undo) a recurring schedule by stamping
  /// `closed_at`. Used by the Recurring Payments Manager actions:
  /// "Cancel subscription", "Mark EMI as completed", and "Close schedule".
  ///
  /// `closed: true`  → sets `closed_at = now()` server-side semantics by
  ///                   passing an ISO timestamp from the client.
  /// `closed: false` → clears `closed_at` back to NULL (Undo snackbar).
  static Future<Transaction> setTransactionClosed(
    int transactionId, {
    required bool closed,
  }) async {
    final userId = requireUserId();

    final payload = <String, dynamic>{
      'closed_at': closed ? DateTime.now().toUtc().toIso8601String() : null,
    };
    final data = await Supabase.instance.client
        .from('transactions')
        .update(payload)
        .eq('id', transactionId)
        .eq('user_id', userId)
        .select()
        .single();

    return Transaction.fromMap(data);
  }

  /// Loads every per-occurrence event the user has logged for any of their
  /// recurring transactions. The manager screen joins these in-memory with
  /// the transaction list to compute the *real* next due date.
  static Future<List<RecurringEvent>> fetchRecurringEvents() async {
    final userId = requireUserId();

    final data = await Supabase.instance.client
        .from('recurring_events')
        .select()
        .eq('user_id', userId)
        .order('occurrence_date', ascending: false);

    return (data as List<dynamic>)
        .map((item) => RecurringEvent.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Records a paid / skipped / snoozed action against a single scheduled
  /// occurrence. Idempotent by `(transaction_id, occurrence_date, event_type)`
  /// thanks to the unique index in `sql/20260528_recurring_events.sql`, so
  /// repeated taps on the same swipe action upsert rather than duplicate.
  static Future<RecurringEvent> insertRecurringEvent(
    RecurringEvent event,
  ) async {
    final userId = requireUserId();

    final payload = event.toMap()..['user_id'] = userId;
    payload.remove('id');
    final data = await Supabase.instance.client
        .from('recurring_events')
        .upsert(
          payload,
          onConflict: 'user_id,transaction_id,occurrence_date,event_type',
        )
        .select()
        .single();

    return RecurringEvent.fromMap(data);
  }

  /// Undoes a previously logged recurring event — used by the "Undo"
  /// affordance on the Mark Paid / Skip / Snooze confirmation snackbars.
  static Future<void> deleteRecurringEvent(int eventId) async {
    final userId = requireUserId();

    await Supabase.instance.client
        .from('recurring_events')
        .delete()
        .eq('id', eventId)
        .eq('user_id', userId);
  }

  static Future<Expense> insertExpense(Expense expense) async {
    final userId = requireUserId();

    final payload = expense.toMap()..['user_id'] = userId;
    final data = await Supabase.instance.client
        .from('transactions')
        .insert(payload)
        .select()
        .single();

    return Expense.fromMap(data);
  }

  static Future<List<Account>> fetchAccounts({
    bool includeArchived = false,
  }) async {
    final userId = requireUserId();

    var query = Supabase.instance.client
        .from('accounts')
        .select()
        .eq('user_id', userId);

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    final data = await query.order('name');

    return (data as List<dynamic>)
        .map((item) => Account.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Account> insertAccount(Account account) async {
    final userId = requireUserId();

    final payload = account.toMap()..['user_id'] = userId;
    final data = await Supabase.instance.client
        .from('accounts')
        .insert(payload)
        .select()
        .single();

    return Account.fromMap(data);
  }

  static Future<Account> updateAccount(Account account) async {
    final userId = requireUserId();
    if (account.id == null) {
      throw Exception('Cannot update an account without an id.');
    }

    final payload = account.toMap()
      ..remove('user_id')
      ..remove('id');
    final data = await Supabase.instance.client
        .from('accounts')
        .update(payload)
        .eq('id', account.id!)
        .eq('user_id', userId)
        .select()
        .single();

    return Account.fromMap(data);
  }

  static Future<Account> archiveAccount(Account account) async {
    return updateAccount(account.copyWith(isArchived: true));
  }

  static Future<List<CategoryBudget>> fetchCategoryBudgets() async {
    final userId = requireUserId();

    final data = await Supabase.instance.client
        .from('category_budgets')
        .select()
        .eq('user_id', userId)
        .order('category_name');

    return (data as List<dynamic>)
        .map((item) => CategoryBudget.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Upserts a budget for `(user_id, category_name)`. The unique index in
  /// `sql/20260527_dashboard_data.sql` is case-insensitive on category name,
  /// so re-saving the same category replaces the existing row.
  static Future<CategoryBudget> upsertCategoryBudget(
    CategoryBudget budget,
  ) async {
    final userId = requireUserId();

    final payload = budget.toMap()
      ..['user_id'] = userId
      ..remove('id');

    final data = await Supabase.instance.client
        .from('category_budgets')
        .upsert(payload, onConflict: 'user_id,category_name')
        .select()
        .single();

    return CategoryBudget.fromMap(data);
  }

  static Future<void> deleteCategoryBudget(int budgetId) async {
    final userId = requireUserId();

    await Supabase.instance.client
        .from('category_budgets')
        .delete()
        .eq('id', budgetId)
        .eq('user_id', userId);
  }

  static Future<Expense> updateExpense(Expense expense) async {
    final userId = requireUserId();

    // Strip identity-bound columns from the update payload so we never
    // attempt to rewrite the row's owner or surrogate id.
    final payload = expense.toMap()
      ..remove('user_id')
      ..remove('id');
    final data = await Supabase.instance.client
        .from('transactions')
        .update(payload)
        .eq('id', expense.id!)
        .eq('user_id', userId)
        .select()
        .single();

    return Expense.fromMap(data);
  }

  static Future<void> deleteExpense(int expenseId) async {
    await deleteTransaction(expenseId);
  }

  static Future<UserSettings?> fetchUserSettings() async {
    final userId = requireUserId();

    final data = await Supabase.instance.client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserSettings.fromMap(data);
  }

  /// Upserts `user_settings` for the current user.
  ///
  /// When [preferences] is null, existing `preferences` on the server are
  /// preserved (used by currency-only updates). When non-null, replaces the
  /// blob (used by [SettingsPreferences] debounced sync).
  static Future<UserSettings> upsertUserSettings(
    String defaultCurrencyCode, {
    Map<String, dynamic>? preferences,
  }) async {
    final userId = requireUserId();

    Map<String, dynamic> resolvedPrefs;
    if (preferences != null) {
      resolvedPrefs = Map<String, dynamic>.from(preferences);
    } else {
      final existing = await Supabase.instance.client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (existing == null) {
        resolvedPrefs = {};
      } else {
        final raw = existing['preferences'];
        if (raw is Map) {
          resolvedPrefs = Map<String, dynamic>.from(raw);
        } else {
          resolvedPrefs = {};
        }
      }
    }

    final data = await Supabase.instance.client
        .from('user_settings')
        .upsert({
          'user_id': userId,
          'default_currency_code': defaultCurrencyCode,
          'preferences': resolvedPrefs,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return UserSettings.fromMap(data);
  }

  static Future<List<ExpenseCategory>> fetchCategories() async {
    final userId = requireUserId();

    final data = await Supabase.instance.client
        .from('expense_categories')
        .select()
        .eq('user_id', userId)
        .order('sort_order')
        .order('name');

    return (data as List<dynamic>)
        .map((item) => ExpenseCategory.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Inserts only default categories the user does not already have.
  static Future<List<ExpenseCategory>> ensureDefaultCategories() async {
    final userId = requireUserId();

    var existing = await fetchCategories();
    final existingNames = existing
        .map((c) => c.name.trim().toLowerCase())
        .toSet();

    final missing = <Map<String, dynamic>>[];
    for (final entry in DefaultCategories.seeds.asMap().entries) {
      final seed = entry.value;
      if (existingNames.contains(seed.name.toLowerCase())) continue;
      missing.add({
        'user_id': userId,
        'name': seed.name,
        'icon': seed.iconKey,
        'sort_order': entry.key,
        'is_default': true,
      });
    }

    if (missing.isNotEmpty) {
      await Supabase.instance.client.from('expense_categories').insert(missing);
      existing = await fetchCategories();
    }

    return existing;
  }

  static Future<ExpenseCategory> insertCategory({
    required String name,
    required String iconKey,
    required int sortOrder,
  }) async {
    final userId = requireUserId();

    final data = await Supabase.instance.client
        .from('expense_categories')
        .insert({
          'user_id': userId,
          'name': name,
          'icon': iconKey,
          'sort_order': sortOrder,
          'is_default': false,
        })
        .select()
        .single();

    return ExpenseCategory.fromMap(data);
  }

  static Future<void> deleteCategory(int categoryId) async {
    final userId = requireUserId();

    await Supabase.instance.client
        .from('expense_categories')
        .delete()
        .eq('id', categoryId)
        .eq('user_id', userId)
        .eq('is_default', false);
  }

  static Future<List<IncomeCategory>> fetchIncomeCategories() async {
    final userId = requireUserId();

    final data = await Supabase.instance.client
        .from('income_categories')
        .select()
        .eq('user_id', userId)
        .order('sort_order')
        .order('name');

    return (data as List<dynamic>)
        .map((item) => IncomeCategory.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<IncomeCategory>> ensureDefaultIncomeCategories() async {
    final userId = requireUserId();

    var existing = await fetchIncomeCategories();
    final existingNames = existing
        .map((c) => c.name.trim().toLowerCase())
        .toSet();

    final missing = <Map<String, dynamic>>[];
    for (final entry in DefaultIncomeCategories.seeds.asMap().entries) {
      final seed = entry.value;
      if (existingNames.contains(seed.name.toLowerCase())) continue;
      missing.add({
        'user_id': userId,
        'name': seed.name,
        'icon': seed.iconKey,
        'sort_order': entry.key,
        'is_default': true,
      });
    }

    if (missing.isNotEmpty) {
      await Supabase.instance.client.from('income_categories').insert(missing);
      existing = await fetchIncomeCategories();
    }

    return existing;
  }

  static Future<IncomeCategory> insertIncomeCategory({
    required String name,
    required String iconKey,
    required int sortOrder,
  }) async {
    final userId = requireUserId();

    final data = await Supabase.instance.client
        .from('income_categories')
        .insert({
          'user_id': userId,
          'name': name,
          'icon': iconKey,
          'sort_order': sortOrder,
          'is_default': false,
        })
        .select()
        .single();

    return IncomeCategory.fromMap(data);
  }

  static Future<void> deleteIncomeCategory(int categoryId) async {
    final userId = requireUserId();

    await Supabase.instance.client
        .from('income_categories')
        .delete()
        .eq('id', categoryId)
        .eq('user_id', userId)
        .eq('is_default', false);
  }
}
