import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker_app/models/transaction.dart';
import 'package:expense_tracker_app/services/api_service.dart';
import 'package:expense_tracker_app/services/auth_service.dart';
import 'package:expense_tracker_app/utils/constants.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AuthService.instance.isGuest.value = false);

  test('guest sessions route to GuestStore and never need a token', () async {
    AuthService.instance.isGuest.value = true;

    final saved = await ApiService.insertTransaction(
      Transaction(amount: 12, counterpartyName: 'Tea', date: DateTime(2026, 1, 1)),
    );
    expect(saved.id, lessThan(0)); // GuestStore's local ids
    expect((await ApiService.fetchTransactions()).single.counterpartyName, 'Tea');

    await ApiService.upsertUserSettings('INR', preferences: {'theme': 'dark'});
    await ApiService.upsertUserSettings('USD'); // currency-only keeps prefs
    final settings = await ApiService.fetchUserSettings();
    expect(settings!.defaultCurrencyCode, 'USD');
    expect(settings.preferences, {'theme': 'dark'});

    await ApiService.resetUserData();
    expect(await ApiService.fetchTransactions(), isEmpty);
    expect(await ApiService.fetchUserSettings(), isNotNull);
  });

  test('signed-out, non-guest calls fail before any network request', () async {
    expect(AuthService.instance.currentSession, isNull);
    await expectLater(
      ApiService.fetchTransactions(),
      throwsA(
        predicate((e) => e.toString().contains(AppConstants.errorNotSignedIn)),
      ),
    );
    // SnackbarHelper.showError falls back to toString(): show the server's message.
    expect(ApiException(409, 'duplicate key').toString(), 'duplicate key');
  });
}
