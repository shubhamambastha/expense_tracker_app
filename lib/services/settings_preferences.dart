import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/design_tokens.dart';
import 'currency_settings.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// App-wide preferences singleton.
///
/// [load] hydrates from [SharedPreferences] for fast cold start. After
/// sign-in, [syncForUser] merges `user_settings.preferences` from Supabase
/// and re-writes local cache. Each change persists locally immediately and
/// schedules a debounced remote upsert when a user session is active.
class SettingsPreferences extends ChangeNotifier {
  SettingsPreferences._();

  static final SettingsPreferences instance = SettingsPreferences._();

  static const _remoteSyncDebounce = Duration(milliseconds: 500);

  // --- Preference keys (also JSON keys in user_settings.preferences) ---
  static const _kDefaultExpenseAccountId = 'pref.default_expense_account_id';
  static const _kMonthlySpendingLimit = 'pref.monthly_spending_limit';
  static const _kSafeDailySpendEnabled = 'pref.safe_daily_spend_enabled';
  static const _kOverspendingAlertsEnabled = 'pref.overspending_alerts_enabled';
  static const _kDisplayName = 'pref.display_name';
  static const _kPhoneNumber = 'pref.phone_number';
  static const _kAvatarRemoved = 'pref.avatar_removed';
  static const _kThemeMode = 'pref.theme_mode';
  static const _kAccentColor = 'pref.accent_color';

  // --- In-memory state with defaults ---
  int? _defaultExpenseAccountId;
  double? _monthlySpendingLimit;
  bool _safeDailySpendEnabled = true;
  bool _overspendingAlertsEnabled = true;
  String _displayName = '';
  String _phoneNumber = '';
  bool _avatarRemoved = false;
  ThemeMode _themeMode = ThemeMode.dark;
  AppAccent _accentColor = AppAccent.teal;

  bool _loaded = false;
  Timer? _remoteSyncTimer;

  bool get isLoaded => _loaded;

  // --- Public getters ---
  int? get defaultExpenseAccountId => _defaultExpenseAccountId;
  double? get monthlySpendingLimit => _monthlySpendingLimit;
  bool get safeDailySpendEnabled => _safeDailySpendEnabled;
  bool get overspendingAlertsEnabled => _overspendingAlertsEnabled;
  String get displayName => _displayName;
  String get phoneNumber => _phoneNumber;
  bool get avatarRemoved => _avatarRemoved;
  ThemeMode get themeMode => _themeMode;
  AppAccent get accentColor => _accentColor;

  /// Pulls remote `preferences` after sign-in (must run after
  /// [CurrencySettings.syncForUser] so `user_settings` exists). Keeps
  /// [SharedPreferences] as the local cache.
  Future<void> syncForUser(String _) async {
    if (!_loaded) {
      await load();
    }

    try {
      final remote = await SupabaseService.fetchUserSettings();
      if (remote == null) {
        await _pushFullRemote();
      } else if (remote.preferences.isEmpty) {
        await _pushFullRemote();
      } else {
        _applyPreferencesJson(remote.preferences);
      }
      await _persistAllToSharedPrefs();
      notifyListeners();
    } catch (error) {
      debugPrint('SettingsPreferences.syncForUser failed: $error');
    }
  }

  void onSignedOut() {
    _remoteSyncTimer?.cancel();
    _remoteSyncTimer = null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _defaultExpenseAccountId = prefs.getInt(_kDefaultExpenseAccountId);
    _monthlySpendingLimit = prefs.getDouble(_kMonthlySpendingLimit);
    _safeDailySpendEnabled =
        prefs.getBool(_kSafeDailySpendEnabled) ?? _safeDailySpendEnabled;
    _overspendingAlertsEnabled =
        prefs.getBool(_kOverspendingAlertsEnabled) ??
        _overspendingAlertsEnabled;
    _displayName = prefs.getString(_kDisplayName) ?? _displayName;
    _phoneNumber = prefs.getString(_kPhoneNumber) ?? _phoneNumber;
    _avatarRemoved = prefs.getBool(_kAvatarRemoved) ?? _avatarRemoved;
    _themeMode = _readEnum(
      prefs.getString(_kThemeMode),
      ThemeMode.values,
      _themeMode,
    );
    _accentColor = _readEnum(
      prefs.getString(_kAccentColor),
      AppAccent.values,
      _accentColor,
    );

    _loaded = true;
    notifyListeners();
  }

  // --- Setters (persist + notify) ---

  Future<void> setDefaultExpenseAccountId(int? value) async {
    if (_defaultExpenseAccountId == value) return;
    _defaultExpenseAccountId = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_kDefaultExpenseAccountId);
    } else {
      await prefs.setInt(_kDefaultExpenseAccountId, value);
    }
    notifyListeners();
    _scheduleRemoteSync();
  }

  Future<void> setMonthlySpendingLimit(double? value) async {
    if (_monthlySpendingLimit == value) return;
    _monthlySpendingLimit = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_kMonthlySpendingLimit);
    } else {
      await prefs.setDouble(_kMonthlySpendingLimit, value);
    }
    notifyListeners();
    _scheduleRemoteSync();
  }

  Future<void> setSafeDailySpendEnabled(bool value) => _writeBool(
    _kSafeDailySpendEnabled,
    value,
    (v) => _safeDailySpendEnabled = v,
  );

  Future<void> setOverspendingAlertsEnabled(bool value) => _writeBool(
    _kOverspendingAlertsEnabled,
    value,
    (v) => _overspendingAlertsEnabled = v,
  );

  Future<void> setDisplayName(String value) async {
    final trimmed = value.trim();
    if (_displayName == trimmed) return;
    _displayName = trimmed;
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_kDisplayName);
    } else {
      await prefs.setString(_kDisplayName, trimmed);
    }
    notifyListeners();
    _scheduleRemoteSync();
  }

  Future<void> setPhoneNumber(String value) async {
    final trimmed = value.trim();
    if (_phoneNumber == trimmed) return;
    _phoneNumber = trimmed;
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_kPhoneNumber);
    } else {
      await prefs.setString(_kPhoneNumber, trimmed);
    }
    notifyListeners();
    _scheduleRemoteSync();
  }

  Future<void> setAvatarRemoved(bool value) =>
      _writeBool(_kAvatarRemoved, value, (v) => _avatarRemoved = v);

  Future<void> setThemeMode(ThemeMode value) =>
      _writeEnum(_kThemeMode, value, (v) => _themeMode = v);

  Future<void> setAccentColor(AppAccent value) =>
      _writeEnum(_kAccentColor, value, (v) => _accentColor = v);

  // --- Remote sync ---

  Map<String, dynamic> preferencesToJson() {
    final m = <String, dynamic>{
      _kDefaultExpenseAccountId: _defaultExpenseAccountId,
      _kMonthlySpendingLimit: _monthlySpendingLimit,
      _kSafeDailySpendEnabled: _safeDailySpendEnabled,
      _kOverspendingAlertsEnabled: _overspendingAlertsEnabled,
      _kDisplayName: _displayName,
      _kPhoneNumber: _phoneNumber,
      _kAvatarRemoved: _avatarRemoved,
      _kThemeMode: _themeMode.name,
      _kAccentColor: _accentColor.name,
    };
    return m;
  }

  void _applyPreferencesJson(Map<String, dynamic> json) {
    if (json.containsKey(_kDefaultExpenseAccountId)) {
      final v = json[_kDefaultExpenseAccountId];
      if (v == null) {
        _defaultExpenseAccountId = null;
      } else if (v is int) {
        _defaultExpenseAccountId = v;
      } else if (v is num) {
        _defaultExpenseAccountId = v.toInt();
      }
    }
    if (json.containsKey(_kMonthlySpendingLimit)) {
      final v = json[_kMonthlySpendingLimit];
      if (v == null) {
        _monthlySpendingLimit = null;
      } else if (v is num) {
        _monthlySpendingLimit = v.toDouble();
      }
    }
    if (json.containsKey(_kSafeDailySpendEnabled)) {
      final v = json[_kSafeDailySpendEnabled];
      if (v is bool) _safeDailySpendEnabled = v;
    }
    if (json.containsKey(_kOverspendingAlertsEnabled)) {
      final v = json[_kOverspendingAlertsEnabled];
      if (v is bool) _overspendingAlertsEnabled = v;
    }
    if (json.containsKey(_kDisplayName)) {
      final v = json[_kDisplayName];
      if (v is String) _displayName = v;
    }
    if (json.containsKey(_kPhoneNumber)) {
      final v = json[_kPhoneNumber];
      if (v is String) _phoneNumber = v;
    }
    if (json.containsKey(_kAvatarRemoved)) {
      final v = json[_kAvatarRemoved];
      if (v is bool) _avatarRemoved = v;
    }
    if (json.containsKey(_kThemeMode)) {
      _themeMode = _readEnum(
        json[_kThemeMode]?.toString(),
        ThemeMode.values,
        _themeMode,
      );
    }
    if (json.containsKey(_kAccentColor)) {
      _accentColor = _readEnum(
        json[_kAccentColor]?.toString(),
        AppAccent.values,
        _accentColor,
      );
    }
  }

  Future<void> _persistAllToSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_defaultExpenseAccountId == null) {
      await prefs.remove(_kDefaultExpenseAccountId);
    } else {
      await prefs.setInt(_kDefaultExpenseAccountId, _defaultExpenseAccountId!);
    }
    if (_monthlySpendingLimit == null) {
      await prefs.remove(_kMonthlySpendingLimit);
    } else {
      await prefs.setDouble(_kMonthlySpendingLimit, _monthlySpendingLimit!);
    }
    await prefs.setBool(_kSafeDailySpendEnabled, _safeDailySpendEnabled);
    await prefs.setBool(
      _kOverspendingAlertsEnabled,
      _overspendingAlertsEnabled,
    );
    if (_displayName.isEmpty) {
      await prefs.remove(_kDisplayName);
    } else {
      await prefs.setString(_kDisplayName, _displayName);
    }
    if (_phoneNumber.isEmpty) {
      await prefs.remove(_kPhoneNumber);
    } else {
      await prefs.setString(_kPhoneNumber, _phoneNumber);
    }
    await prefs.setBool(_kAvatarRemoved, _avatarRemoved);
    await prefs.setString(_kThemeMode, _themeMode.name);
    await prefs.setString(_kAccentColor, _accentColor.name);
  }

  Future<void> _pushFullRemote() async {
    if (AuthService.instance.currentSession == null) return;
    final code = CurrencySettings.instance.currencyCode;
    await SupabaseService.upsertUserSettings(
      code,
      preferences: preferencesToJson(),
    );
  }

  void _scheduleRemoteSync() {
    if (AuthService.instance.currentSession == null) return;
    _remoteSyncTimer?.cancel();
    _remoteSyncTimer = Timer(_remoteSyncDebounce, () async {
      _remoteSyncTimer = null;
      try {
        final code = CurrencySettings.instance.currencyCode;
        await SupabaseService.upsertUserSettings(
          code,
          preferences: preferencesToJson(),
        );
      } catch (error) {
        debugPrint('SettingsPreferences remote sync failed: $error');
      }
    });
  }

  // --- Private helpers ---

  Future<void> _writeBool(
    String key,
    bool value,
    void Function(bool) apply,
  ) async {
    apply(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    notifyListeners();
    _scheduleRemoteSync();
  }

  Future<void> _writeEnum<T extends Enum>(
    String key,
    T value,
    void Function(T) apply,
  ) async {
    apply(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value.name);
    notifyListeners();
    _scheduleRemoteSync();
  }

  T _readEnum<T extends Enum>(String? raw, List<T> values, T fallback) {
    if (raw == null) return fallback;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }
}
