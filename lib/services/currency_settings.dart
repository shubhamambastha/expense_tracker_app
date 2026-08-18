import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'supabase_service.dart';

/// A supported currency for display and expense input.
class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
    required this.locale,
  });

  final String code;
  final String name;
  final String symbol;
  final String locale;
}

/// App-wide default currency (profile-only). Synced to Supabase per user when
/// signed in; cached locally for fast startup and offline use.
class CurrencySettings extends ChangeNotifier {
  CurrencySettings._();

  static final CurrencySettings instance = CurrencySettings._();

  static const defaultCode = 'USD';

  static const List<CurrencyOption> supported = [
    CurrencyOption(
      code: 'USD',
      name: 'US Dollar',
      symbol: r'$',
      locale: 'en_US',
    ),
    CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€', locale: 'de_DE'),
    CurrencyOption(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      locale: 'en_GB',
    ),
    CurrencyOption(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      locale: 'en_IN',
    ),
    CurrencyOption(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: r'C$',
      locale: 'en_CA',
    ),
    CurrencyOption(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: r'A$',
      locale: 'en_AU',
    ),
    CurrencyOption(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      locale: 'ja_JP',
    ),
    CurrencyOption(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'CHF',
      locale: 'de_CH',
    ),
    CurrencyOption(
      code: 'SGD',
      name: 'Singapore Dollar',
      symbol: r'S$',
      locale: 'en_SG',
    ),
    CurrencyOption(
      code: 'AED',
      name: 'UAE Dirham',
      symbol: 'AED',
      locale: 'ar_AE',
    ),
  ];

  String _code = defaultCode;
  String? _activeUserId;
  bool _loaded = false;

  String get currencyCode => _code;
  bool get isLoaded => _loaded;

  static bool isSupportedCode(String code) =>
      supported.any((c) => c.code == code);

  CurrencyOption get current => supported.firstWhere(
    (c) => c.code == _code,
    orElse: () => supported.first,
  );

  String get symbol => current.symbol;

  String get inputPrefix => '$symbol ';

  int get decimalDigits => _code == 'JPY' ? 0 : 2;

  NumberFormat get formatter => NumberFormat.currency(
    locale: current.locale,
    symbol: symbol,
    decimalDigits: decimalDigits,
  );

  NumberFormat get compactFormatter => NumberFormat.compactCurrency(
    locale: current.locale,
    symbol: symbol,
    decimalDigits: decimalDigits,
  );

  String format(double amount) => formatter.format(amount);

  /// `intl`'s en_IN compact-currency pattern mislabels the 1,000-99,999
  /// range as "T" (trillion) instead of Lakh/Crore tiers — e.g. ₹66,000
  /// renders as "₹66T". The Indian numbering system doesn't abbreviate
  /// below 1 lakh anyway, so fall back to the plain formatter there.
  String formatCompact(double amount) {
    if (_code == 'INR' && amount.abs() < 100000) return format(amount);
    return compactFormatter.format(amount);
  }

  static String _prefKeyFor(String? userId) => userId == null
      ? 'default_currency_code'
      : 'default_currency_code_$userId';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyFor(null));
    if (saved != null && isSupportedCode(saved)) {
      _code = saved;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Pull settings from Supabase after sign-in; creates a row if missing.
  Future<void> syncForUser(String userId) async {
    _activeUserId = userId;

    try {
      final remote = await SupabaseService.fetchUserSettings();
      if (remote != null && isSupportedCode(remote.defaultCurrencyCode)) {
        await _applyCode(remote.defaultCurrencyCode, persistRemote: false);
        return;
      }

      await SupabaseService.upsertUserSettings(_code);
      await _cacheLocally(userId, _code);
    } catch (error) {
      debugPrint('CurrencySettings.syncForUser failed: $error');
      await _loadCachedForUser(userId);
    }
  }

  void onSignedOut() {
    _activeUserId = null;
  }

  Future<void> setCurrency(String code) async {
    if (!isSupportedCode(code)) return;
    if (_code == code) return;

    await _applyCode(code, persistRemote: true);
  }

  Future<void> _applyCode(String code, {required bool persistRemote}) async {
    _code = code;
    final userId = _activeUserId ?? AuthService.instance.currentSession?.userId;
    await _cacheLocally(userId, code);

    if (persistRemote && userId != null) {
      try {
        await SupabaseService.upsertUserSettings(code);
      } catch (error) {
        debugPrint('CurrencySettings.setCurrency remote save failed: $error');
      }
    }

    notifyListeners();
  }

  Future<void> _loadCachedForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyFor(userId));
    if (saved != null && isSupportedCode(saved)) {
      _code = saved;
      notifyListeners();
    }
  }

  Future<void> _cacheLocally(String? userId, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyFor(userId), code);
    if (userId != null) {
      await prefs.setString(_prefKeyFor(null), code);
    }
  }
}
