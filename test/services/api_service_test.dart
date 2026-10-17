import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'package:jebbo/models/transaction.dart';
import 'package:jebbo/services/api_service.dart';
import 'package:jebbo/services/auth_service.dart';
import 'package:jebbo/utils/constants.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AuthService.instance.isGuest.value = false);

  test('guest sessions route to GuestStore and never need a token', () async {
    AuthService.instance.isGuest.value = true;

    final saved = await ApiService.insertTransaction(
      Transaction(
        amount: 12,
        counterpartyName: 'Tea',
        date: DateTime(2026, 1, 1),
      ),
    );
    expect(saved.id, lessThan(0)); // GuestStore's local ids
    expect(
      (await ApiService.fetchTransactions()).single.counterpartyName,
      'Tea',
    );

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

  group('signed in', () {
    final realClient = ApiService.client;
    final realTokenSource = ApiService.tokenSource;
    final requests = <http.Request>[];
    final tokenCalls = <bool>[];

    setUp(() {
      requests.clear();
      tokenCalls.clear();
      AuthService.instance.setUser(
        const User(
          id: 'u1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-12T00:00:00Z',
        ),
      );
      ApiService.tokenSource = ({bool forceRefresh = false}) async {
        tokenCalls.add(forceRefresh);
        return forceRefresh ? 'fresh' : 'stale';
      };
    });
    tearDown(() {
      AuthService.instance.setUser(null);
      ApiService.client = realClient;
      ApiService.tokenSource = realTokenSource;
    });

    void respond(List<int> statuses) {
      var i = 0;
      ApiService.client = MockClient((request) async {
        requests.add(request);
        final status = statuses[i++];
        return http.Response(
          status == 200
              ? '[]'
              : status == 204
              ? ''
              : '{"error":"Invalid or expired token"}',
          status,
          // Express sends a 204 with no body and no content-type.
          headers: status == 204 ? {} : {'content-type': 'application/json'},
        );
      });
    }

    test('a 401 retries once with a force-refreshed token', () async {
      respond([401, 200]);
      expect(await ApiService.fetchTransactions(), isEmpty);
      expect(tokenCalls, [false, true]);
      expect(requests.map((r) => r.headers['Authorization']), [
        'Bearer stale',
        'Bearer fresh',
      ]);
    });

    test('a second 401 surfaces as an error instead of looping', () async {
      respond([401, 401]);
      await expectLater(
        ApiService.fetchTransactions(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
      expect(requests, hasLength(2));
    });

    test(
      'deleteUserAccount sends DELETE /v1/account with the bearer token',
      () async {
        respond([204]);
        await ApiService.deleteUserAccount();
        expect(requests.single.method, 'DELETE');
        expect(requests.single.url.path, endsWith('/v1/account'));
        expect(requests.single.headers['Authorization'], 'Bearer stale');
      },
    );

    test('other failures are not retried and never force a refresh', () async {
      respond([500]);
      await expectLater(
        ApiService.deleteUserAccount(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 500)),
      );
      expect(requests, hasLength(1));
      expect(tokenCalls, [false]);
    });
  });
}
