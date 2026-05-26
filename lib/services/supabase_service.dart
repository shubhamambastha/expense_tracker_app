import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';
import '../models/expense.dart';
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
    const urlFromDefine = 'https://axabbtuvufmahbgzmczk.supabase.co';
    const anonFromDefine = 'sb_publishable_M1CWmWJTonBVm9JMcIaF8w_RYskfFKS';

    final url = urlFromDefine.isNotEmpty ? urlFromDefine : '';
    final anon = anonFromDefine.isNotEmpty ? anonFromDefine : '';

    if (url.isEmpty || anon.isEmpty) {
      throw Exception(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Provide via --dart-define',
      );
    }

    await Supabase.initialize(url: url, anonKey: anon, debug: true);
  }

  static User? get currentUser => Supabase.instance.client.auth.currentUser;

  static Stream<dynamic> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  static Future<AuthResponse> signInWithEmail(
    String email,
    String password,
  ) async {
    return Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
  ) async {
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  static Future<List<Transaction>> fetchTransactions() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to load transactions.');
    }

    final data = await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('user_id', user.id)
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
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to save transactions.');
    }

    final payload = transaction.toMap()..['user_id'] = user.id;
    payload.remove('id');
    final data = await Supabase.instance.client
        .from('transactions')
        .insert(payload)
        .select()
        .single();

    return Transaction.fromMap(data);
  }

  static Future<Transaction> updateTransaction(Transaction transaction) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to update transactions.');
    }

    final payload = transaction.toMap()
      ..remove('user_id')
      ..remove('id');
    final data = await Supabase.instance.client
        .from('transactions')
        .update(payload)
        .eq('id', transaction.id!)
        .eq('user_id', user.id)
        .select()
        .single();

    return Transaction.fromMap(data);
  }

  static Future<void> deleteTransaction(int transactionId) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to delete transactions.');
    }

    await Supabase.instance.client
        .from('transactions')
        .delete()
        .eq('id', transactionId)
        .eq('user_id', user.id);
  }

  static Future<Expense> insertExpense(Expense expense) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to save expenses.');
    }

    final payload = expense.toMap()..['user_id'] = user.id;
    final data = await Supabase.instance.client
        .from('transactions')
        .insert(payload)
        .select()
        .single();

    return Expense.fromMap(data);
  }

  static Future<List<Account>> fetchAccounts() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to load accounts.');
    }

    final data = await Supabase.instance.client
        .from('accounts')
        .select()
        .eq('user_id', user.id)
        .order('name');

    return (data as List<dynamic>)
        .map((item) => Account.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Account> insertAccount(Account account) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to save accounts.');
    }

    final payload = account.toMap()..['user_id'] = user.id;
    final data = await Supabase.instance.client
        .from('accounts')
        .insert(payload)
        .select()
        .single();

    return Account.fromMap(data);
  }

  static Future<Expense> updateExpense(Expense expense) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to update expenses.');
    }

    // Strip identity-bound columns from the update payload so we never
    // attempt to rewrite the row's owner or surrogate id.
    final payload = expense.toMap()
      ..remove('user_id')
      ..remove('id');
    final data = await Supabase.instance.client
        .from('transactions')
        .update(payload)
        .eq('id', expense.id!)
        .eq('user_id', user.id)
        .select()
        .single();

    return Expense.fromMap(data);
  }

  static Future<void> deleteExpense(int expenseId) async {
    await deleteTransaction(expenseId);
  }

  static Future<UserSettings?> fetchUserSettings() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to load settings.');
    }

    final data = await Supabase.instance.client
        .from('user_settings')
        .select()
        .eq('user_id', user.id)
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
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to save settings.');
    }

    Map<String, dynamic> resolvedPrefs;
    if (preferences != null) {
      resolvedPrefs = Map<String, dynamic>.from(preferences);
    } else {
      final existing = await Supabase.instance.client
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
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
          'user_id': user.id,
          'default_currency_code': defaultCurrencyCode,
          'preferences': resolvedPrefs,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return UserSettings.fromMap(data);
  }

  static Future<List<ExpenseCategory>> fetchCategories() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to load categories.');
    }

    final data = await Supabase.instance.client
        .from('expense_categories')
        .select()
        .eq('user_id', user.id)
        .order('sort_order')
        .order('name');

    return (data as List<dynamic>)
        .map((item) => ExpenseCategory.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Inserts only default categories the user does not already have.
  static Future<List<ExpenseCategory>> ensureDefaultCategories() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to seed categories.');
    }

    var existing = await fetchCategories();
    final existingNames = existing
        .map((c) => c.name.trim().toLowerCase())
        .toSet();

    final missing = <Map<String, dynamic>>[];
    for (final entry in DefaultCategories.seeds.asMap().entries) {
      final seed = entry.value;
      if (existingNames.contains(seed.name.toLowerCase())) continue;
      missing.add({
        'user_id': user.id,
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
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to save categories.');
    }

    final data = await Supabase.instance.client
        .from('expense_categories')
        .insert({
          'user_id': user.id,
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
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to delete categories.');
    }

    await Supabase.instance.client
        .from('expense_categories')
        .delete()
        .eq('id', categoryId)
        .eq('user_id', user.id)
        .eq('is_default', false);
  }

  static Future<List<IncomeCategory>> fetchIncomeCategories() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to load income categories.');
    }

    final data = await Supabase.instance.client
        .from('income_categories')
        .select()
        .eq('user_id', user.id)
        .order('sort_order')
        .order('name');

    return (data as List<dynamic>)
        .map((item) => IncomeCategory.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<IncomeCategory>> ensureDefaultIncomeCategories() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to seed income categories.');
    }

    var existing = await fetchIncomeCategories();
    final existingNames = existing
        .map((c) => c.name.trim().toLowerCase())
        .toSet();

    final missing = <Map<String, dynamic>>[];
    for (final entry in DefaultIncomeCategories.seeds.asMap().entries) {
      final seed = entry.value;
      if (existingNames.contains(seed.name.toLowerCase())) continue;
      missing.add({
        'user_id': user.id,
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
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to save income categories.');
    }

    final data = await Supabase.instance.client
        .from('income_categories')
        .insert({
          'user_id': user.id,
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
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to delete income categories.');
    }

    await Supabase.instance.client
        .from('income_categories')
        .delete()
        .eq('id', categoryId)
        .eq('user_id', user.id)
        .eq('is_default', false);
  }
}
