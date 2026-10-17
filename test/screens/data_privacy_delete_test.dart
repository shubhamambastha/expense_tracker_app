import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'package:expense_tracker_app/screens/settings/sections/data_privacy_page.dart';
import 'package:expense_tracker_app/services/api_service.dart';
import 'package:expense_tracker_app/services/auth_service.dart';

void main() {
  final realClient = ApiService.client;
  final realTokenSource = ApiService.tokenSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.instance.setUser(
      const User(
        id: 'u1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-12T00:00:00Z',
      ),
    );
    ApiService.tokenSource = ({bool forceRefresh = false}) async => 't';
  });
  tearDown(() {
    AuthService.instance.setUser(null);
    ApiService.client = realClient;
    ApiService.tokenSource = realTokenSource;
  });

  /// Pushes DataPrivacyPage over a root route and confirms the delete dialog.
  Future<void> deleteAccount(
    WidgetTester tester,
    VoidCallback onDeleted,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DataPrivacyPage(
                  onAccountReset: () {},
                  onGuestDataChanged: () {},
                  onAccountDeleted: onDeleted,
                ),
              ),
            ),
            child: const Text('root'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('root'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete Account'), 200);
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'DELETE',
    );
    await tester.pump();
    await tester.tap(find.text('Delete forever'));
    // Not pumpAndSettle: the error snackbar removes itself once its 2.4s animation ends.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('a failed delete keeps the user signed in on the page', (
    tester,
  ) async {
    ApiService.client = MockClient(
      (_) async => http.Response(
        '{"error":"Internal server error"}',
        500,
        headers: {'content-type': 'application/json'},
      ),
    );
    var deleted = 0;
    await deleteAccount(tester, () => deleted++);

    expect(deleted, 0);
    expect(find.byType(DataPrivacyPage), findsOneWidget);
    expect(
      find.textContaining('Could not delete your account'),
      findsOneWidget,
    );
    expect(find.text('Deleting…'), findsNothing);
    await tester.pumpAndSettle(); // let the snackbar finish
  });

  testWidgets('a successful delete pops back to the root, then signs out', (
    tester,
  ) async {
    ApiService.client = MockClient((request) async {
      expect([request.method, request.url.path], ['DELETE', '/v1/account']);
      return http.Response('', 204);
    });
    var deleted = 0;
    await deleteAccount(tester, () => deleted++);
    await tester.pumpAndSettle();

    expect(deleted, 1);
    expect(find.byType(DataPrivacyPage), findsNothing);
    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('signed-in Export Data asks the API to email the CSVs', (
    tester,
  ) async {
    ApiService.client = MockClient((request) async {
      expect([request.method, request.url.path], ['POST', '/v1/data/export']);
      return http.Response(
        '{"email":"me@example.com"}',
        202,
        headers: {'content-type': 'application/json'},
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: DataPrivacyPage(
          onAccountReset: () {},
          onGuestDataChanged: () {},
          onAccountDeleted: () {},
        ),
      ),
    );
    await tester.tap(find.text('Export Data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Your data is on its way to me@example.com'),
      findsOneWidget,
    );
    await tester.pumpAndSettle(); // let the snackbar finish
  });
}
