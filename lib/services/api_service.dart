import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/app_config.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'guest_store.dart';
import '../models/account.dart';
import '../models/category_budget.dart';
import '../models/recurring_event.dart';
import '../models/transaction.dart';
import '../models/expense_category.dart';
import '../models/income_category.dart';
import '../models/user_settings.dart';
import '../utils/category_style.dart';

/// Non-2xx response from the backend; [message] is the server's `error` field.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// All persistence for signed-in users goes through the Node API in
/// `backend/` (see docs/BACKEND.md), which scopes every row to the Auth0
/// `sub` in the bearer token. Guest sessions stay on-device in [GuestStore].
class ApiService {
  ApiService._();

  static final _client = http.Client();

  /// Tolerates a trailing slash in `API_BASE_URL` (otherwise `//v1/...` 404s).
  static final _baseUrl = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');

  static const _timeout = Duration(seconds: 20);

  static Future<void> init() async {
    if (!AppConfig.hasApi) {
      throw Exception('Missing API_BASE_URL. Provide via --dart-define');
    }
    // dart:io ignores iOS ATS and Android cleartext rules, so this is the
    // only thing stopping a release build from sending tokens over plain HTTP.
    if (kReleaseMode && !_baseUrl.startsWith('https://')) {
      throw Exception('API_BASE_URL must be https:// in release builds');
    }
    await AuthService.instance.init();
  }

  /// Single choke point: every method below branches here first. Guest
  /// sessions never reach the network at all.
  static bool get _isGuest => AuthService.instance.isGuest.value;

  static Future<dynamic> _send(
    String method,
    String path, [
    Object? body,
  ]) async {
    if (AuthService.instance.currentSession == null) {
      throw Exception(AppConstants.errorNotSignedIn);
    }
    var response = await _sendWith(await _idToken(), method, path, body);
    if (response.statusCode == 401) {
      // Rejected before any write happened (expired, clock skew, rotated
      // key), so one retry with a freshly renewed token is safe.
      final renewed = await _idToken(forceRenew: true);
      response = await _sendWith(renewed, method, path, body);
    }
    return decode(response);
  }

  /// Auth0's `credentials()` only renews when the *access* token expires,
  /// but the API verifies the shorter-lived ID token, so renew when that
  /// one is about to lapse.
  static Future<String> _idToken({bool forceRenew = false}) async {
    var creds = await AuthService.instance.credentials();
    if (forceRenew || _expiresSoon(creds.idToken)) {
      creds = await AuthService.instance.auth0.credentialsManager
          .renewCredentials();
    }
    return creds.idToken;
  }

  static bool _expiresSoon(String jwt) {
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(jwt.split('.')[1]))),
      );
      final exp = DateTime.fromMillisecondsSinceEpoch(
        (payload['exp'] as int) * 1000,
      );
      return exp.isBefore(DateTime.now().add(const Duration(minutes: 1)));
    } catch (_) {
      return false; // Unreadable token: let the server decide.
    }
  }

  static Future<http.Response> _sendWith(
    String token,
    String method,
    String path,
    Object? body,
  ) async {
    final request = http.Request(method, Uri.parse('$_baseUrl/v1$path'))
      ..headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_timeout);
    } on TimeoutException {
      throw ApiException(408, 'The server took too long to respond.');
    }
  }

  /// Only 2xx is success: a 3xx (e.g. http→https redirect on a DELETE) must
  /// not look like the write happened. 204 / empty body → null.
  @visibleForTesting
  static dynamic decode(http.Response response) {
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    final isJson =
        response.headers['content-type']?.contains('application/json') ?? false;
    Object? data;
    if (isJson) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        if (ok) rethrow;
      }
    } else if (ok && response.body.isNotEmpty) {
      // Captive portal / proxy page instead of the API.
      throw ApiException(
        response.statusCode,
        'Unexpected response from server.',
      );
    }
    if (!ok) {
      throw ApiException(
        response.statusCode,
        (data is Map ? data['error'] as String? : null) ??
            'Request failed (${response.statusCode})',
      );
    }
    return data;
  }

  static List<T> _list<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromMap,
  ) => [for (final item in data as List) fromMap(item as Map<String, dynamic>)];

  static Future<List<Transaction>> fetchTransactions() async {
    if (_isGuest) return GuestStore.instance.fetchTransactions();
    return _list(await _send('GET', '/transactions'), Transaction.fromMap);
  }

  static Future<Transaction> insertTransaction(Transaction transaction) async {
    if (_isGuest) return GuestStore.instance.insertTransaction(transaction);
    return Transaction.fromMap(
      await _send('POST', '/transactions', transaction.toMap()),
    );
  }

  static Future<Transaction> updateTransaction(Transaction transaction) async {
    if (_isGuest) return GuestStore.instance.updateTransaction(transaction);
    return _patchTransaction(transaction.id!, transaction.toMap());
  }

  static Future<Transaction> _patchTransaction(
    int transactionId,
    Map<String, dynamic> fields,
  ) async => Transaction.fromMap(
    await _send('PATCH', '/transactions/$transactionId', fields),
  );

  static Future<void> deleteTransaction(int transactionId) async {
    if (_isGuest) return GuestStore.instance.deleteTransaction(transactionId);
    await _send('DELETE', '/transactions/$transactionId');
  }

  /// Toggles the `is_paused` flag on a recurring transaction without losing
  /// any of its schedule metadata. Used by the Recurring Payments Manager
  /// "Pause / Resume" action.
  static Future<Transaction> setTransactionPaused(
    int transactionId,
    bool paused,
  ) async {
    if (_isGuest) {
      return GuestStore.instance.setTransactionPaused(transactionId, paused);
    }
    return _patchTransaction(transactionId, {'is_paused': paused});
  }

  /// Terminates (or re-opens via Undo) a recurring schedule by stamping
  /// `closed_at`. Used by the Recurring Payments Manager actions:
  /// "Cancel subscription", "Mark EMI as completed", and "Close schedule".
  ///
  /// `closed: true`  → sets `closed_at` to the client's current UTC time.
  /// `closed: false` → clears `closed_at` back to NULL (Undo snackbar).
  static Future<Transaction> setTransactionClosed(
    int transactionId, {
    required bool closed,
  }) async {
    if (_isGuest) {
      return GuestStore.instance.setTransactionClosed(
        transactionId,
        closed: closed,
      );
    }
    return _patchTransaction(transactionId, {
      'closed_at': closed ? DateTime.now().toUtc().toIso8601String() : null,
    });
  }

  /// Loads every per-occurrence event the user has logged for any of their
  /// recurring transactions. The manager screen joins these in-memory with
  /// the transaction list to compute the *real* next due date.
  static Future<List<RecurringEvent>> fetchRecurringEvents() async {
    if (_isGuest) return GuestStore.instance.fetchRecurringEvents();
    return _list(
      await _send('GET', '/recurring-events'),
      RecurringEvent.fromMap,
    );
  }

  /// Records a paid / skipped / snoozed action against a single scheduled
  /// occurrence. The server upserts on
  /// `(user_id, transaction_id, occurrence_date, event_type)`, so repeated
  /// taps on the same swipe action don't duplicate.
  static Future<RecurringEvent> insertRecurringEvent(
    RecurringEvent event,
  ) async {
    if (_isGuest) return GuestStore.instance.insertRecurringEvent(event);
    return RecurringEvent.fromMap(
      await _send('POST', '/recurring-events', event.toMap()),
    );
  }

  /// Undoes a previously logged recurring event — used by the "Undo"
  /// affordance on the Mark Paid / Skip / Snooze confirmation snackbars.
  static Future<void> deleteRecurringEvent(int eventId) async {
    if (_isGuest) return GuestStore.instance.deleteRecurringEvent(eventId);
    await _send('DELETE', '/recurring-events/$eventId');
  }

  static Future<List<Account>> fetchAccounts({
    bool includeArchived = false,
  }) async {
    if (_isGuest) {
      return GuestStore.instance.fetchAccounts(
        includeArchived: includeArchived,
      );
    }
    final query = includeArchived ? '?includeArchived=true' : '';
    return _list(await _send('GET', '/accounts$query'), Account.fromMap);
  }

  static Future<Account> insertAccount(Account account) async {
    if (_isGuest) return GuestStore.instance.insertAccount(account);
    return Account.fromMap(await _send('POST', '/accounts', account.toMap()));
  }

  static Future<Account> updateAccount(Account account) async {
    if (account.id == null) {
      throw Exception('Cannot update an account without an id.');
    }
    if (_isGuest) return GuestStore.instance.updateAccount(account);
    return Account.fromMap(
      await _send('PATCH', '/accounts/${account.id}', account.toMap()),
    );
  }

  static Future<Account> archiveAccount(Account account) async {
    return updateAccount(account.copyWith(isArchived: true));
  }

  /// Hard delete — not exposed anywhere in the UI (soft-archive is the
  /// user-facing path). Exists solely so [GuestMigrationService] can roll
  /// back accounts it inserted this attempt if migration fails partway.
  static Future<void> deleteAccount(int accountId) async {
    if (_isGuest) return GuestStore.instance.deleteAccount(accountId);
    await _send('DELETE', '/accounts/$accountId');
  }

  static Future<List<CategoryBudget>> fetchCategoryBudgets() async {
    if (_isGuest) return GuestStore.instance.fetchCategoryBudgets();
    return _list(await _send('GET', '/budgets'), CategoryBudget.fromMap);
  }

  /// Upserts a budget for `(user_id, category_name)`, so re-saving the same
  /// category replaces the existing row.
  static Future<CategoryBudget> upsertCategoryBudget(
    CategoryBudget budget,
  ) async {
    if (_isGuest) return GuestStore.instance.upsertCategoryBudget(budget);
    return CategoryBudget.fromMap(
      await _send('POST', '/budgets', budget.toMap()),
    );
  }

  static Future<void> deleteCategoryBudget(int budgetId) async {
    if (_isGuest) return GuestStore.instance.deleteCategoryBudget(budgetId);
    await _send('DELETE', '/budgets/$budgetId');
  }

  static Future<UserSettings?> fetchUserSettings() async {
    if (_isGuest) return GuestStore.instance.fetchUserSettings();
    final data = await _send('GET', '/settings');
    return data == null ? null : UserSettings.fromMap(data);
  }

  /// Upserts `user_settings` for the current user.
  ///
  /// When [preferences] is null it is left out of the payload, so the
  /// server keeps the existing blob (used by currency-only updates). When
  /// non-null, replaces it (used by [SettingsPreferences] debounced sync).
  static Future<UserSettings> upsertUserSettings(
    String defaultCurrencyCode, {
    Map<String, dynamic>? preferences,
  }) async {
    if (_isGuest) {
      return GuestStore.instance.upsertUserSettings(
        defaultCurrencyCode,
        preferences: preferences,
      );
    }
    return UserSettings.fromMap(
      await _send('PATCH', '/settings', {
        'default_currency_code': defaultCurrencyCode,
        'preferences': ?preferences,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  /// Marks the real account's onboarding wizard complete. Only ever touches
  /// this one column — the server upserts only the columns sent, so this is
  /// safe from `SettingsPreferences`' broader `preferences` sync (see
  /// docs/designs/post-login-onboarding.md, T5eng).
  static Future<void> markOnboardingComplete() async {
    await _send('PATCH', '/settings', {
      'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Seed rows the user doesn't already have (case-insensitive by name).
  static List<Map<String, dynamic>> _missingSeeds(
    Iterable<String> existingNames,
    List<({String name, String iconKey})> seeds,
  ) {
    final have = existingNames.map((n) => n.trim().toLowerCase()).toSet();
    return [
      for (final (index, seed) in seeds.indexed)
        if (!have.contains(seed.name.toLowerCase()))
          {
            'name': seed.name,
            'icon': seed.iconKey,
            'sort_order': index,
            'is_default': true,
          },
    ];
  }

  static Future<List<ExpenseCategory>> fetchCategories() async {
    if (_isGuest) return GuestStore.instance.fetchCategories();
    return _list(
      await _send('GET', '/categories/expense'),
      ExpenseCategory.fromMap,
    );
  }

  /// Inserts only default categories the user does not already have.
  static Future<List<ExpenseCategory>> ensureDefaultCategories() async {
    if (_isGuest) return GuestStore.instance.ensureDefaultCategories();
    final existing = await fetchCategories();
    final missing = _missingSeeds(
      existing.map((c) => c.name),
      DefaultCategories.seeds,
    );
    if (missing.isEmpty) return existing;
    await _send('POST', '/categories/expense', missing);
    return fetchCategories();
  }

  static Future<ExpenseCategory> insertCategory({
    required String name,
    required String iconKey,
    required int sortOrder,
  }) async {
    if (_isGuest) {
      return GuestStore.instance.insertCategory(
        name: name,
        iconKey: iconKey,
        sortOrder: sortOrder,
      );
    }
    return ExpenseCategory.fromMap(
      await _send('POST', '/categories/expense', {
        'name': name,
        'icon': iconKey,
        'sort_order': sortOrder,
        'is_default': false,
      }),
    );
  }

  /// Deleting a seeded default (`is_default = true`) is a silent no-op on the
  /// server (still 204), matching the old direct-Supabase behaviour.
  static Future<void> deleteCategory(int categoryId) async {
    if (_isGuest) return GuestStore.instance.deleteCategory(categoryId);
    await _send('DELETE', '/categories/expense/$categoryId');
  }

  static Future<List<IncomeCategory>> fetchIncomeCategories() async {
    if (_isGuest) return GuestStore.instance.fetchIncomeCategories();
    return _list(
      await _send('GET', '/categories/income'),
      IncomeCategory.fromMap,
    );
  }

  static Future<List<IncomeCategory>> ensureDefaultIncomeCategories() async {
    if (_isGuest) return GuestStore.instance.ensureDefaultIncomeCategories();
    final existing = await fetchIncomeCategories();
    final missing = _missingSeeds(
      existing.map((c) => c.name),
      DefaultIncomeCategories.seeds,
    );
    if (missing.isEmpty) return existing;
    await _send('POST', '/categories/income', missing);
    return fetchIncomeCategories();
  }

  static Future<IncomeCategory> insertIncomeCategory({
    required String name,
    required String iconKey,
    required int sortOrder,
  }) async {
    if (_isGuest) {
      return GuestStore.instance.insertIncomeCategory(
        name: name,
        iconKey: iconKey,
        sortOrder: sortOrder,
      );
    }
    return IncomeCategory.fromMap(
      await _send('POST', '/categories/income', {
        'name': name,
        'icon': iconKey,
        'sort_order': sortOrder,
        'is_default': false,
      }),
    );
  }

  static Future<void> deleteIncomeCategory(int categoryId) async {
    if (_isGuest) return GuestStore.instance.deleteIncomeCategory(categoryId);
    await _send('DELETE', '/categories/income/$categoryId');
  }

  /// Wipes every user-owned row *except* `user_settings` (preferences +
  /// currency) and the Auth0 session itself — used by "Reset My Account" in
  /// Help Center.
  static Future<void> resetUserData() async {
    if (_isGuest) return GuestStore.instance.resetUserData();
    await _send('DELETE', '/data');
  }
}
