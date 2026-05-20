import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
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

  static Future<List<Expense>> fetchExpenses() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to load expenses.');
    }

    final data = await Supabase.instance.client
        .from('expenses')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false);

    return (data as List<dynamic>)
        .map((item) => Expense.fromMap(item as Map<String, dynamic>))
        .toList();
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

  static Future<Expense> insertExpense(Expense expense) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to save expenses.');
    }

    final payload = expense.toMap()..['user_id'] = user.id;
    final data = await Supabase.instance.client
        .from('expenses')
        .insert(payload)
        .select()
        .single();

    return Expense.fromMap(data);
  }

  static Future<Expense> updateExpense(Expense expense) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to update expenses.');
    }

    final payload = expense.toMap()
      ..['user_id'] = user.id
      ..remove('user_id');
    final data = await Supabase.instance.client
        .from('expenses')
        .update(payload)
        .eq('id', expense.id!)
        .select()
        .single();

    return Expense.fromMap(data);
  }

  static Future<void> deleteExpense(int expenseId) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to delete expenses.');
    }

    await Supabase.instance.client
        .from('expenses')
        .delete()
        .eq('id', expenseId)
        .eq('user_id', user.id);
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

  static Future<UserSettings> upsertUserSettings(
    String defaultCurrencyCode,
  ) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to save settings.');
    }

    final payload = UserSettings(
      userId: user.id,
      defaultCurrencyCode: defaultCurrencyCode,
    ).toMap();

    final data = await Supabase.instance.client
        .from('user_settings')
        .upsert(payload)
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
}
