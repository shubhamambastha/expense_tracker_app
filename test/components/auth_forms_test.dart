import 'package:expense_tracker_app/components/auth/login_form.dart';
import 'package:expense_tracker_app/components/settings/settings_delete_account_tile.dart';
import 'package:expense_tracker_app/screens/auth/reset_password_page.dart';
import 'package:expense_tracker_app/screens/auth/verify_email_page.dart';
import 'package:expense_tracker_app/utils/snackbar_helper.dart';
import 'package:expense_tracker_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

// Only validation paths that return before AuthService (and so Supabase) is touched.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump(const Duration(seconds: 1)); // let entry animations finish
}

void main() {
  testWidgets('sign-in form blocks empty submits and trims the email', (
    tester,
  ) async {
    final submitted = <List<String>>[];
    await _pump(
      tester,
      LoginForm(
        isSignUp: false,
        isLoading: false,
        onSubmit: (e, p) => submitted.add([e, p]),
        onToggleMode: () {},
        onForgotPassword: (_) {},
      ),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(submitted, isEmpty);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      ' me@example.com ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'x');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(submitted, [
      ['me@example.com', 'x'],
    ]);
  });

  testWidgets('sign-up form enforces the minimum password length', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      LoginForm(
        isSignUp: true,
        isLoading: false,
        onSubmit: (_, _) => calls++,
        onToggleMode: () {},
        onForgotPassword: (_) {},
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'me@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(
      find.text('Use at least $minPasswordLength characters'),
      findsOneWidget,
    );
    expect(calls, 0);
    expect(find.text('Forgot password?'), findsNothing);
  });

  testWidgets('loading disables submit, mode toggle and forgot password', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      LoginForm(
        isSignUp: false,
        isLoading: true,
        onSubmit: (_, _) => taps++,
        onToggleMode: () => taps++,
        onForgotPassword: (_) => taps++,
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.tap(find.text('Forgot password?'));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets(
    'verify page rejects a short code and holds resend during the cooldown',
    (tester) async {
      await _pump(tester, const VerifyEmailPage(email: 'me@example.com'));

      final resend = tester.widget<TextButton>(
        find.ancestor(
          of: find.textContaining('Resend code in'),
          matching: find.byType(TextButton),
        ),
      );
      expect(resend.onPressed, isNull);

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('Verify'));
      await tester.pump();
      expect(find.text('Enter the code from the email'), findsOneWidget);

      await tester.pumpWidget(const SizedBox()); // dispose the cooldown timer
    },
  );

  testWidgets('reset page validates the email before sending a code', (
    tester,
  ) async {
    await _pump(tester, const ResetPasswordPage(initialEmail: 'nope'));

    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Set new password'), findsNothing); // still on step one
  });

  testWidgets('delete tile shows progress and ignores taps while deleting', (
    tester,
  ) async {
    await _pump(
      tester,
      SettingsDeleteAccountTile(
        isDeleting: true,
        onDeleteConfirmed: () async {},
      ),
    );
    expect(find.text('Deleting…'), findsOneWidget);
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    var confirmed = 0;
    await _pump(
      tester,
      SettingsDeleteAccountTile(onDeleteConfirmed: () async => confirmed++),
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(confirmed, 0, reason: 'Cancel must never delete');

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
    await tester.pumpAndSettle();
    expect(confirmed, 1);
  });

  testWidgets('auth errors show the Supabase message, not the exception dump', (
    tester,
  ) async {
    await _pump(tester, const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    SnackbarHelper.showError(
      context,
      const AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Invalid login credentials'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10)); // let it auto-dismiss
  });
}
