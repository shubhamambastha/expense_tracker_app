import 'package:expense_tracker_app/services/app_launch_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLaunchIntentHolder.fromUri', () {
    test('parses expensetracker://add-expense host form', () {
      expect(
        AppLaunchIntentHolder.fromUri(Uri.parse('expensetracker://add-expense')),
        AppLaunchIntent.addExpense,
      );
    });

    test('parses expensetracker:///add-expense path form', () {
      expect(
        AppLaunchIntentHolder.fromUri(Uri.parse('expensetracker:///add-expense')),
        AppLaunchIntent.addExpense,
      );
    });

    test('returns null for unknown paths', () {
      expect(
        AppLaunchIntentHolder.fromUri(Uri.parse('expensetracker://unknown')),
        isNull,
      );
    });

    test('returns null for other schemes', () {
      expect(
        AppLaunchIntentHolder.fromUri(Uri.parse('https://add-expense')),
        isNull,
      );
    });
  });

  group('AppLaunchIntentHolder consume', () {
    test('consume clears pending intent', () {
      final holder = AppLaunchIntentHolder.instance;
      holder.set(AppLaunchIntent.addExpense);
      expect(holder.consume(), AppLaunchIntent.addExpense);
      expect(holder.consume(), isNull);
    });
  });
}
