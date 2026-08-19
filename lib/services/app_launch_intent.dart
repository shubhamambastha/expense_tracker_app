import 'package:flutter/foundation.dart';

/// Deep-link / widget launch actions consumed by [ExpenseHomePage].
enum AppLaunchIntent {
  addExpense,
  addIncome,
  openAnalytics,
}

/// Holds a pending launch intent until the home screen consumes it.
class AppLaunchIntentHolder {
  AppLaunchIntentHolder._();

  static final AppLaunchIntentHolder instance = AppLaunchIntentHolder._();

  final ValueNotifier<AppLaunchIntent?> pending = ValueNotifier(null);

  void set(AppLaunchIntent intent) {
    pending.value = intent;
  }

  /// Returns and clears the pending intent, if any.
  AppLaunchIntent? consume() {
    final value = pending.value;
    if (value != null) {
      pending.value = null;
    }
    return value;
  }

  /// Maps `expensetracker://add-expense` (and path variants) to an intent.
  static AppLaunchIntent? fromUri(Uri uri) {
    if (uri.scheme != 'expensetracker') return null;

    final segment = (uri.host.isNotEmpty
            ? uri.host
            : uri.path.replaceFirst(RegExp(r'^/'), ''))
        .split('/')
        .first
        .toLowerCase();
    if (segment.isEmpty) return null;

    switch (segment) {
      case 'add-expense':
        return AppLaunchIntent.addExpense;
      case 'add-income':
        return AppLaunchIntent.addIncome;
      case 'open-analytics':
        return AppLaunchIntent.openAnalytics;
      default:
        return null;
    }
  }
}
