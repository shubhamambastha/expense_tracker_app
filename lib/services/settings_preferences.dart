import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/design_tokens.dart';
import 'currency_settings.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// Persistent default for the Add Transaction screen.
enum DefaultTransactionType { expense, income }

extension DefaultTransactionTypeLabel on DefaultTransactionType {
  String get label {
    switch (this) {
      case DefaultTransactionType.expense:
        return 'Expense';
      case DefaultTransactionType.income:
        return 'Income';
    }
  }
}

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
  static const _kMultiCurrencyEnabled = 'pref.multi_currency_enabled';
  static const _kDefaultExpenseAccountId = 'pref.default_expense_account_id';
  static const _kDefaultIncomeAccountId = 'pref.default_income_account_id';
  static const _kDefaultTransactionType = 'pref.default_transaction_type';
  static const _kMonthlySpendingLimit = 'pref.monthly_spending_limit';
  static const _kSafeDailySpendEnabled = 'pref.safe_daily_spend_enabled';
  static const _kOverspendingAlertsEnabled = 'pref.overspending_alerts_enabled';
  static const _kNotifRecurringEnabled = 'pref.notif_recurring_enabled';
  static const _kNotifSalaryEnabled = 'pref.notif_salary_enabled';
  static const _kNotifBudgetEnabled = 'pref.notif_budget_enabled';
  static const _kNotifInsightsEnabled = 'pref.notif_insights_enabled';
  static const _kAiAssistantEnabled = 'pref.ai_assistant_enabled';
  static const _kAiInsightsEnabled = 'pref.ai_insights_enabled';
  static const _kAppLockEnabled = 'pref.app_lock_enabled';
  static const _kHapticEnabled = 'pref.haptic_enabled';
  static const _kAnimationsEnabled = 'pref.animations_enabled';
  static const _kCompactModeEnabled = 'pref.compact_mode_enabled';
  static const _kDisplayName = 'pref.display_name';
  static const _kPhoneNumber = 'pref.phone_number';
  static const _kTimezoneId = 'pref.timezone_id';
  static const _kAvatarRemoved = 'pref.avatar_removed';
  static const _kThemeMode = 'pref.theme_mode';
  static const _kAccentColor = 'pref.accent_color';

  /// Sentinel stored in [_timezoneId] to follow the device timezone.
  static const deviceTimezoneId = 'device';

  // --- In-memory state with defaults ---
  bool _multiCurrencyEnabled = false;
  int? _defaultExpenseAccountId;
  int? _defaultIncomeAccountId;
  DefaultTransactionType _defaultTransactionType =
      DefaultTransactionType.expense;
  double? _monthlySpendingLimit;
  bool _safeDailySpendEnabled = true;
  bool _overspendingAlertsEnabled = true;
  bool _notifRecurringEnabled = true;
  bool _notifSalaryEnabled = true;
  bool _notifBudgetEnabled = true;
  bool _notifInsightsEnabled = false;
  bool _aiAssistantEnabled = true;
  bool _aiInsightsEnabled = true;
  bool _appLockEnabled = false;
  bool _hapticEnabled = true;
  bool _animationsEnabled = true;
  bool _compactModeEnabled = false;
  String _displayName = '';
  String _phoneNumber = '';
  String _timezoneId = deviceTimezoneId;
  bool _avatarRemoved = false;
  ThemeMode _themeMode = ThemeMode.dark;
  AppAccent _accentColor = AppAccent.teal;

  bool _loaded = false;
  Timer? _remoteSyncTimer;

  bool get isLoaded => _loaded;

  // --- Public getters ---
  bool get multiCurrencyEnabled => _multiCurrencyEnabled;
  int? get defaultExpenseAccountId => _defaultExpenseAccountId;
  int? get defaultIncomeAccountId => _defaultIncomeAccountId;
  DefaultTransactionType get defaultTransactionType => _defaultTransactionType;
  double? get monthlySpendingLimit => _monthlySpendingLimit;
  bool get safeDailySpendEnabled => _safeDailySpendEnabled;
  bool get overspendingAlertsEnabled => _overspendingAlertsEnabled;
  bool get notifRecurringEnabled => _notifRecurringEnabled;
  bool get notifSalaryEnabled => _notifSalaryEnabled;
  bool get notifBudgetEnabled => _notifBudgetEnabled;
  bool get notifInsightsEnabled => _notifInsightsEnabled;
  bool get aiAssistantEnabled => _aiAssistantEnabled;
  bool get aiInsightsEnabled => _aiInsightsEnabled;
  bool get appLockEnabled => _appLockEnabled;
  bool get hapticEnabled => _hapticEnabled;
  bool get animationsEnabled => _animationsEnabled;
  bool get compactModeEnabled => _compactModeEnabled;
  String get displayName => _displayName;
  String get phoneNumber => _phoneNumber;
  String get timezoneId => _timezoneId;
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

    _multiCurrencyEnabled =
        prefs.getBool(_kMultiCurrencyEnabled) ?? _multiCurrencyEnabled;
    _defaultExpenseAccountId = prefs.getInt(_kDefaultExpenseAccountId);
    _defaultIncomeAccountId = prefs.getInt(_kDefaultIncomeAccountId);
    _defaultTransactionType = _readEnum(
      prefs.getString(_kDefaultTransactionType),
      DefaultTransactionType.values,
      _defaultTransactionType,
    );
    _monthlySpendingLimit = prefs.getDouble(_kMonthlySpendingLimit);
    _safeDailySpendEnabled =
        prefs.getBool(_kSafeDailySpendEnabled) ?? _safeDailySpendEnabled;
    _overspendingAlertsEnabled =
        prefs.getBool(_kOverspendingAlertsEnabled) ??
        _overspendingAlertsEnabled;
    _notifRecurringEnabled =
        prefs.getBool(_kNotifRecurringEnabled) ?? _notifRecurringEnabled;
    _notifSalaryEnabled =
        prefs.getBool(_kNotifSalaryEnabled) ?? _notifSalaryEnabled;
    _notifBudgetEnabled =
        prefs.getBool(_kNotifBudgetEnabled) ?? _notifBudgetEnabled;
    _notifInsightsEnabled =
        prefs.getBool(_kNotifInsightsEnabled) ?? _notifInsightsEnabled;
    _aiAssistantEnabled =
        prefs.getBool(_kAiAssistantEnabled) ?? _aiAssistantEnabled;
    _aiInsightsEnabled =
        prefs.getBool(_kAiInsightsEnabled) ?? _aiInsightsEnabled;
    _appLockEnabled = prefs.getBool(_kAppLockEnabled) ?? _appLockEnabled;
    _hapticEnabled = prefs.getBool(_kHapticEnabled) ?? _hapticEnabled;
    _animationsEnabled =
        prefs.getBool(_kAnimationsEnabled) ?? _animationsEnabled;
    _compactModeEnabled =
        prefs.getBool(_kCompactModeEnabled) ?? _compactModeEnabled;
    _displayName = prefs.getString(_kDisplayName) ?? _displayName;
    _phoneNumber = prefs.getString(_kPhoneNumber) ?? _phoneNumber;
    _timezoneId = prefs.getString(_kTimezoneId) ?? _timezoneId;
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

  Future<void> setMultiCurrencyEnabled(bool value) => _writeBool(
    _kMultiCurrencyEnabled,
    value,
    (v) => _multiCurrencyEnabled = v,
  );

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

  Future<void> setDefaultIncomeAccountId(int? value) async {
    if (_defaultIncomeAccountId == value) return;
    _defaultIncomeAccountId = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_kDefaultIncomeAccountId);
    } else {
      await prefs.setInt(_kDefaultIncomeAccountId, value);
    }
    notifyListeners();
    _scheduleRemoteSync();
  }

  Future<void> setDefaultTransactionType(DefaultTransactionType value) =>
      _writeEnum(
        _kDefaultTransactionType,
        value,
        (v) => _defaultTransactionType = v,
      );

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

  Future<void> setNotifRecurringEnabled(bool value) => _writeBool(
    _kNotifRecurringEnabled,
    value,
    (v) => _notifRecurringEnabled = v,
  );

  Future<void> setNotifSalaryEnabled(bool value) =>
      _writeBool(_kNotifSalaryEnabled, value, (v) => _notifSalaryEnabled = v);

  Future<void> setNotifBudgetEnabled(bool value) =>
      _writeBool(_kNotifBudgetEnabled, value, (v) => _notifBudgetEnabled = v);

  Future<void> setNotifInsightsEnabled(bool value) => _writeBool(
    _kNotifInsightsEnabled,
    value,
    (v) => _notifInsightsEnabled = v,
  );

  Future<void> setAiAssistantEnabled(bool value) =>
      _writeBool(_kAiAssistantEnabled, value, (v) => _aiAssistantEnabled = v);

  Future<void> setAiInsightsEnabled(bool value) =>
      _writeBool(_kAiInsightsEnabled, value, (v) => _aiInsightsEnabled = v);

  Future<void> setAppLockEnabled(bool value) =>
      _writeBool(_kAppLockEnabled, value, (v) => _appLockEnabled = v);

  Future<void> setHapticEnabled(bool value) =>
      _writeBool(_kHapticEnabled, value, (v) => _hapticEnabled = v);

  Future<void> setAnimationsEnabled(bool value) =>
      _writeBool(_kAnimationsEnabled, value, (v) => _animationsEnabled = v);

  Future<void> setCompactModeEnabled(bool value) =>
      _writeBool(_kCompactModeEnabled, value, (v) => _compactModeEnabled = v);

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

  Future<void> setTimezoneId(String value) =>
      _writeString(_kTimezoneId, value, (v) => _timezoneId = v);

  Future<void> setAvatarRemoved(bool value) =>
      _writeBool(_kAvatarRemoved, value, (v) => _avatarRemoved = v);

  Future<void> setThemeMode(ThemeMode value) =>
      _writeEnum(_kThemeMode, value, (v) => _themeMode = v);

  Future<void> setAccentColor(AppAccent value) =>
      _writeEnum(_kAccentColor, value, (v) => _accentColor = v);

  // --- Remote sync ---

  Map<String, dynamic> preferencesToJson() {
    final m = <String, dynamic>{
      _kMultiCurrencyEnabled: _multiCurrencyEnabled,
      _kDefaultExpenseAccountId: _defaultExpenseAccountId,
      _kDefaultIncomeAccountId: _defaultIncomeAccountId,
      _kDefaultTransactionType: _defaultTransactionType.name,
      _kMonthlySpendingLimit: _monthlySpendingLimit,
      _kSafeDailySpendEnabled: _safeDailySpendEnabled,
      _kOverspendingAlertsEnabled: _overspendingAlertsEnabled,
      _kNotifRecurringEnabled: _notifRecurringEnabled,
      _kNotifSalaryEnabled: _notifSalaryEnabled,
      _kNotifBudgetEnabled: _notifBudgetEnabled,
      _kNotifInsightsEnabled: _notifInsightsEnabled,
      _kAiAssistantEnabled: _aiAssistantEnabled,
      _kAiInsightsEnabled: _aiInsightsEnabled,
      _kAppLockEnabled: _appLockEnabled,
      _kHapticEnabled: _hapticEnabled,
      _kAnimationsEnabled: _animationsEnabled,
      _kCompactModeEnabled: _compactModeEnabled,
      _kDisplayName: _displayName,
      _kPhoneNumber: _phoneNumber,
      _kTimezoneId: _timezoneId,
      _kAvatarRemoved: _avatarRemoved,
      _kThemeMode: _themeMode.name,
      _kAccentColor: _accentColor.name,
    };
    return m;
  }

  void _applyPreferencesJson(Map<String, dynamic> json) {
    if (json.containsKey(_kMultiCurrencyEnabled)) {
      final v = json[_kMultiCurrencyEnabled];
      if (v is bool) _multiCurrencyEnabled = v;
    }
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
    if (json.containsKey(_kDefaultIncomeAccountId)) {
      final v = json[_kDefaultIncomeAccountId];
      if (v == null) {
        _defaultIncomeAccountId = null;
      } else if (v is int) {
        _defaultIncomeAccountId = v;
      } else if (v is num) {
        _defaultIncomeAccountId = v.toInt();
      }
    }
    if (json.containsKey(_kDefaultTransactionType)) {
      _defaultTransactionType = _readEnum(
        json[_kDefaultTransactionType]?.toString(),
        DefaultTransactionType.values,
        _defaultTransactionType,
      );
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
    if (json.containsKey(_kNotifRecurringEnabled)) {
      final v = json[_kNotifRecurringEnabled];
      if (v is bool) _notifRecurringEnabled = v;
    }
    if (json.containsKey(_kNotifSalaryEnabled)) {
      final v = json[_kNotifSalaryEnabled];
      if (v is bool) _notifSalaryEnabled = v;
    }
    if (json.containsKey(_kNotifBudgetEnabled)) {
      final v = json[_kNotifBudgetEnabled];
      if (v is bool) _notifBudgetEnabled = v;
    }
    if (json.containsKey(_kNotifInsightsEnabled)) {
      final v = json[_kNotifInsightsEnabled];
      if (v is bool) _notifInsightsEnabled = v;
    }
    if (json.containsKey(_kAiAssistantEnabled)) {
      final v = json[_kAiAssistantEnabled];
      if (v is bool) _aiAssistantEnabled = v;
    }
    if (json.containsKey(_kAiInsightsEnabled)) {
      final v = json[_kAiInsightsEnabled];
      if (v is bool) _aiInsightsEnabled = v;
    }
    if (json.containsKey(_kAppLockEnabled)) {
      final v = json[_kAppLockEnabled];
      if (v is bool) _appLockEnabled = v;
    }
    if (json.containsKey(_kHapticEnabled)) {
      final v = json[_kHapticEnabled];
      if (v is bool) _hapticEnabled = v;
    }
    if (json.containsKey(_kAnimationsEnabled)) {
      final v = json[_kAnimationsEnabled];
      if (v is bool) _animationsEnabled = v;
    }
    if (json.containsKey(_kCompactModeEnabled)) {
      final v = json[_kCompactModeEnabled];
      if (v is bool) _compactModeEnabled = v;
    }
    if (json.containsKey(_kDisplayName)) {
      final v = json[_kDisplayName];
      if (v is String) _displayName = v;
    }
    if (json.containsKey(_kPhoneNumber)) {
      final v = json[_kPhoneNumber];
      if (v is String) _phoneNumber = v;
    }
    if (json.containsKey(_kTimezoneId)) {
      final v = json[_kTimezoneId];
      if (v is String && v.isNotEmpty) _timezoneId = v;
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
    await prefs.setBool(_kMultiCurrencyEnabled, _multiCurrencyEnabled);
    if (_defaultExpenseAccountId == null) {
      await prefs.remove(_kDefaultExpenseAccountId);
    } else {
      await prefs.setInt(_kDefaultExpenseAccountId, _defaultExpenseAccountId!);
    }
    if (_defaultIncomeAccountId == null) {
      await prefs.remove(_kDefaultIncomeAccountId);
    } else {
      await prefs.setInt(_kDefaultIncomeAccountId, _defaultIncomeAccountId!);
    }
    await prefs.setString(
      _kDefaultTransactionType,
      _defaultTransactionType.name,
    );
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
    await prefs.setBool(_kNotifRecurringEnabled, _notifRecurringEnabled);
    await prefs.setBool(_kNotifSalaryEnabled, _notifSalaryEnabled);
    await prefs.setBool(_kNotifBudgetEnabled, _notifBudgetEnabled);
    await prefs.setBool(_kNotifInsightsEnabled, _notifInsightsEnabled);
    await prefs.setBool(_kAiAssistantEnabled, _aiAssistantEnabled);
    await prefs.setBool(_kAiInsightsEnabled, _aiInsightsEnabled);
    await prefs.setBool(_kAppLockEnabled, _appLockEnabled);
    await prefs.setBool(_kHapticEnabled, _hapticEnabled);
    await prefs.setBool(_kAnimationsEnabled, _animationsEnabled);
    await prefs.setBool(_kCompactModeEnabled, _compactModeEnabled);
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
    await prefs.setString(_kTimezoneId, _timezoneId);
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

  Future<void> _writeString(
    String key,
    String value,
    void Function(String) apply,
  ) async {
    apply(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
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
