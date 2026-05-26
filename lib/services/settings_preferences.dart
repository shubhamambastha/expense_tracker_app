import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// Mirrors the shape of [CurrencySettings] (`ChangeNotifier`, lazy `load()`,
/// `SharedPreferences`-backed cache). Toggles & enum pickers persist across
/// launches; Supabase sync can be layered on later by extending [load] and
/// each setter.
class SettingsPreferences extends ChangeNotifier {
  SettingsPreferences._();

  static final SettingsPreferences instance = SettingsPreferences._();

  // --- Preference keys ---
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
  }

  T _readEnum<T extends Enum>(String? raw, List<T> values, T fallback) {
    if (raw == null) return fallback;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }
}
