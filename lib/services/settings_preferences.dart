import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'currency_settings.dart';
import 'supabase_service.dart';

/// Fiscal year boundary used for analytics & budgeting roll-ups.
enum FinancialYear { janDec, aprMar }

extension FinancialYearLabel on FinancialYear {
  String get label {
    switch (this) {
      case FinancialYear.janDec:
        return 'Jan – Dec';
      case FinancialYear.aprMar:
        return 'Apr – Mar';
    }
  }

  String get short {
    switch (this) {
      case FinancialYear.janDec:
        return 'Jan–Dec';
      case FinancialYear.aprMar:
        return 'Apr–Mar';
    }
  }
}

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

/// When notifications fire relative to the event date.
enum NotificationTiming { sameDay, oneDayBefore, threeDaysBefore }

extension NotificationTimingLabel on NotificationTiming {
  String get label {
    switch (this) {
      case NotificationTiming.sameDay:
        return 'Same day';
      case NotificationTiming.oneDayBefore:
        return '1 day before';
      case NotificationTiming.threeDaysBefore:
        return '3 days before';
    }
  }
}

/// Theme preference. Stored only — rendering stays dark for this iteration.
enum ThemeModePref { system, light, dark }

extension ThemeModePrefLabel on ThemeModePref {
  String get label {
    switch (this) {
      case ThemeModePref.system:
        return 'System';
      case ThemeModePref.light:
        return 'Light';
      case ThemeModePref.dark:
        return 'Dark';
    }
  }
}

/// Output format for "Export Data".
enum ExportFormat { csv, json }

extension ExportFormatLabel on ExportFormat {
  String get label {
    switch (this) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.json:
        return 'JSON';
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
  static const _kFinancialYear = 'pref.financial_year';
  static const _kDefaultExpenseAccountId = 'pref.default_expense_account_id';
  static const _kDefaultIncomeAccountId = 'pref.default_income_account_id';
  static const _kDefaultTransactionType = 'pref.default_transaction_type';
  static const _kMonthlySpendingLimit = 'pref.monthly_spending_limit';
  static const _kSafeDailySpendEnabled = 'pref.safe_daily_spend_enabled';
  static const _kOverspendingAlertsEnabled =
      'pref.overspending_alerts_enabled';
  static const _kNotifRecurringEnabled = 'pref.notif_recurring_enabled';
  static const _kNotifSalaryEnabled = 'pref.notif_salary_enabled';
  static const _kNotifBudgetEnabled = 'pref.notif_budget_enabled';
  static const _kNotifInsightsEnabled = 'pref.notif_insights_enabled';
  static const _kNotifTiming = 'pref.notif_timing';
  static const _kAiAssistantEnabled = 'pref.ai_assistant_enabled';
  static const _kAiInsightsEnabled = 'pref.ai_insights_enabled';
  static const _kThemeModePref = 'pref.theme_mode_pref';
  static const _kAppLockEnabled = 'pref.app_lock_enabled';
  static const _kHapticEnabled = 'pref.haptic_enabled';
  static const _kAnimationsEnabled = 'pref.animations_enabled';
  static const _kCompactModeEnabled = 'pref.compact_mode_enabled';

  // --- In-memory state with defaults ---
  bool _multiCurrencyEnabled = false;
  FinancialYear _financialYear = FinancialYear.janDec;
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
  NotificationTiming _notifTiming = NotificationTiming.oneDayBefore;
  bool _aiAssistantEnabled = true;
  bool _aiInsightsEnabled = true;
  ThemeModePref _themeModePref = ThemeModePref.dark;
  bool _appLockEnabled = false;
  bool _hapticEnabled = true;
  bool _animationsEnabled = true;
  bool _compactModeEnabled = false;

  bool _loaded = false;
  Timer? _remoteSyncTimer;

  bool get isLoaded => _loaded;

  // --- Public getters ---
  bool get multiCurrencyEnabled => _multiCurrencyEnabled;
  FinancialYear get financialYear => _financialYear;
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
  NotificationTiming get notifTiming => _notifTiming;
  bool get aiAssistantEnabled => _aiAssistantEnabled;
  bool get aiInsightsEnabled => _aiInsightsEnabled;
  ThemeModePref get themeModePref => _themeModePref;
  bool get appLockEnabled => _appLockEnabled;
  bool get hapticEnabled => _hapticEnabled;
  bool get animationsEnabled => _animationsEnabled;
  bool get compactModeEnabled => _compactModeEnabled;

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
    _financialYear = _readEnum(
      prefs.getString(_kFinancialYear),
      FinancialYear.values,
      _financialYear,
    );
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
    _overspendingAlertsEnabled = prefs.getBool(_kOverspendingAlertsEnabled) ??
        _overspendingAlertsEnabled;
    _notifRecurringEnabled =
        prefs.getBool(_kNotifRecurringEnabled) ?? _notifRecurringEnabled;
    _notifSalaryEnabled =
        prefs.getBool(_kNotifSalaryEnabled) ?? _notifSalaryEnabled;
    _notifBudgetEnabled =
        prefs.getBool(_kNotifBudgetEnabled) ?? _notifBudgetEnabled;
    _notifInsightsEnabled =
        prefs.getBool(_kNotifInsightsEnabled) ?? _notifInsightsEnabled;
    _notifTiming = _readEnum(
      prefs.getString(_kNotifTiming),
      NotificationTiming.values,
      _notifTiming,
    );
    _aiAssistantEnabled =
        prefs.getBool(_kAiAssistantEnabled) ?? _aiAssistantEnabled;
    _aiInsightsEnabled =
        prefs.getBool(_kAiInsightsEnabled) ?? _aiInsightsEnabled;
    _themeModePref = _readEnum(
      prefs.getString(_kThemeModePref),
      ThemeModePref.values,
      _themeModePref,
    );
    _appLockEnabled = prefs.getBool(_kAppLockEnabled) ?? _appLockEnabled;
    _hapticEnabled = prefs.getBool(_kHapticEnabled) ?? _hapticEnabled;
    _animationsEnabled =
        prefs.getBool(_kAnimationsEnabled) ?? _animationsEnabled;
    _compactModeEnabled =
        prefs.getBool(_kCompactModeEnabled) ?? _compactModeEnabled;

    _loaded = true;
    notifyListeners();
  }

  // --- Setters (persist + notify) ---

  Future<void> setMultiCurrencyEnabled(bool value) =>
      _writeBool(_kMultiCurrencyEnabled, value, (v) => _multiCurrencyEnabled = v);

  Future<void> setFinancialYear(FinancialYear value) =>
      _writeEnum(_kFinancialYear, value, (v) => _financialYear = v);

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
      _writeEnum(_kDefaultTransactionType, value,
          (v) => _defaultTransactionType = v);

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

  Future<void> setNotifTiming(NotificationTiming value) =>
      _writeEnum(_kNotifTiming, value, (v) => _notifTiming = v);

  Future<void> setAiAssistantEnabled(bool value) =>
      _writeBool(_kAiAssistantEnabled, value, (v) => _aiAssistantEnabled = v);

  Future<void> setAiInsightsEnabled(bool value) =>
      _writeBool(_kAiInsightsEnabled, value, (v) => _aiInsightsEnabled = v);

  Future<void> setThemeModePref(ThemeModePref value) =>
      _writeEnum(_kThemeModePref, value, (v) => _themeModePref = v);

  Future<void> setAppLockEnabled(bool value) =>
      _writeBool(_kAppLockEnabled, value, (v) => _appLockEnabled = v);

  Future<void> setHapticEnabled(bool value) =>
      _writeBool(_kHapticEnabled, value, (v) => _hapticEnabled = v);

  Future<void> setAnimationsEnabled(bool value) =>
      _writeBool(_kAnimationsEnabled, value, (v) => _animationsEnabled = v);

  Future<void> setCompactModeEnabled(bool value) =>
      _writeBool(_kCompactModeEnabled, value, (v) => _compactModeEnabled = v);

  // --- Remote sync ---

  Map<String, dynamic> preferencesToJson() {
    final m = <String, dynamic>{
      _kMultiCurrencyEnabled: _multiCurrencyEnabled,
      _kFinancialYear: _financialYear.name,
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
      _kNotifTiming: _notifTiming.name,
      _kAiAssistantEnabled: _aiAssistantEnabled,
      _kAiInsightsEnabled: _aiInsightsEnabled,
      _kThemeModePref: _themeModePref.name,
      _kAppLockEnabled: _appLockEnabled,
      _kHapticEnabled: _hapticEnabled,
      _kAnimationsEnabled: _animationsEnabled,
      _kCompactModeEnabled: _compactModeEnabled,
    };
    return m;
  }

  void _applyPreferencesJson(Map<String, dynamic> json) {
    if (json.containsKey(_kMultiCurrencyEnabled)) {
      final v = json[_kMultiCurrencyEnabled];
      if (v is bool) _multiCurrencyEnabled = v;
    }
    if (json.containsKey(_kFinancialYear)) {
      _financialYear = _readEnum(
        json[_kFinancialYear]?.toString(),
        FinancialYear.values,
        _financialYear,
      );
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
    if (json.containsKey(_kNotifTiming)) {
      _notifTiming = _readEnum(
        json[_kNotifTiming]?.toString(),
        NotificationTiming.values,
        _notifTiming,
      );
    }
    if (json.containsKey(_kAiAssistantEnabled)) {
      final v = json[_kAiAssistantEnabled];
      if (v is bool) _aiAssistantEnabled = v;
    }
    if (json.containsKey(_kAiInsightsEnabled)) {
      final v = json[_kAiInsightsEnabled];
      if (v is bool) _aiInsightsEnabled = v;
    }
    if (json.containsKey(_kThemeModePref)) {
      _themeModePref = _readEnum(
        json[_kThemeModePref]?.toString(),
        ThemeModePref.values,
        _themeModePref,
      );
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
  }

  Future<void> _persistAllToSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMultiCurrencyEnabled, _multiCurrencyEnabled);
    await prefs.setString(_kFinancialYear, _financialYear.name);
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
    await prefs.setString(_kDefaultTransactionType, _defaultTransactionType.name);
    if (_monthlySpendingLimit == null) {
      await prefs.remove(_kMonthlySpendingLimit);
    } else {
      await prefs.setDouble(_kMonthlySpendingLimit, _monthlySpendingLimit!);
    }
    await prefs.setBool(_kSafeDailySpendEnabled, _safeDailySpendEnabled);
    await prefs.setBool(_kOverspendingAlertsEnabled, _overspendingAlertsEnabled);
    await prefs.setBool(_kNotifRecurringEnabled, _notifRecurringEnabled);
    await prefs.setBool(_kNotifSalaryEnabled, _notifSalaryEnabled);
    await prefs.setBool(_kNotifBudgetEnabled, _notifBudgetEnabled);
    await prefs.setBool(_kNotifInsightsEnabled, _notifInsightsEnabled);
    await prefs.setString(_kNotifTiming, _notifTiming.name);
    await prefs.setBool(_kAiAssistantEnabled, _aiAssistantEnabled);
    await prefs.setBool(_kAiInsightsEnabled, _aiInsightsEnabled);
    await prefs.setString(_kThemeModePref, _themeModePref.name);
    await prefs.setBool(_kAppLockEnabled, _appLockEnabled);
    await prefs.setBool(_kHapticEnabled, _hapticEnabled);
    await prefs.setBool(_kAnimationsEnabled, _animationsEnabled);
    await prefs.setBool(_kCompactModeEnabled, _compactModeEnabled);
  }

  Future<void> _pushFullRemote() async {
    if (SupabaseService.currentUser == null) return;
    final code = CurrencySettings.instance.currencyCode;
    await SupabaseService.upsertUserSettings(
      code,
      preferences: preferencesToJson(),
    );
  }

  void _scheduleRemoteSync() {
    if (SupabaseService.currentUser == null) return;
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
