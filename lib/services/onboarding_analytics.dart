import 'package:shared_preferences/shared_preferences.dart';

/// Minimal local counters for the onboarding wizard — this app has no
/// product analytics anywhere (Open Question #10), so this is the only
/// data this feature gets at scale beyond one manual Assignment
/// observation. Inspectable via a debug menu; never sent anywhere.
class OnboardingAnalytics {
  OnboardingAnalytics._();

  static const _kStarted = 'onboarding_analytics_started';
  static const _kCompleted = 'onboarding_analytics_completed';
  static const _kSkippedPrefix = 'onboarding_analytics_skipped_';

  static Future<void> recordStarted() => _increment(_kStarted);

  static Future<void> recordCompleted() => _increment(_kCompleted);

  static Future<void> recordStepSkipped(String stepId) =>
      _increment('$_kSkippedPrefix$stepId');

  static Future<void> _increment(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }

  /// Debug-menu snapshot: started/completed counts plus a skip count per
  /// step id ('name', 'currency', 'budget', 'income', 'recurring').
  static Future<Map<String, int>> snapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, int>{
      'started': prefs.getInt(_kStarted) ?? 0,
      'completed': prefs.getInt(_kCompleted) ?? 0,
    };
    for (final step in const [
      'name',
      'currency',
      'budget',
      'income',
      'recurring',
    ]) {
      result['skipped_$step'] = prefs.getInt('$_kSkippedPrefix$step') ?? 0;
    }
    return result;
  }
}
