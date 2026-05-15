import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

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
      throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY. Provide via --dart-define');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anon,
      debug: true,
    );
  }

  static User? get currentUser => Supabase.instance.client.auth.currentUser;

  static Stream<dynamic> get authStateChanges => Supabase.instance.client.auth.onAuthStateChange;

  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
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
}
