import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../components/auth/auth_page_scaffold.dart';
import '../../components/auth/login_form.dart';
import '../../components/auth/social_sign_in_buttons.dart';
import '../../config/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../utils/app_config.dart';
import '../../utils/snackbar_helper.dart';
import 'reset_password_page.dart';
import 'verify_email_page.dart';

/// Email + password, Google, Apple (iOS), or guest.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _isSignUp = false;

  /// Runs a sign-in attempt. On success AuthGate's session listener takes
  /// over (syncs user data, then switches phases), so stay loading until
  /// this page is replaced.
  Future<void> _run(Future<void> Function() attempt) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await attempt();
    } on AuthLoginCancelledException {
      if (mounted) setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit(String email, String password) => _run(() async {
    final auth = AuthService.instance;
    if (_isSignUp) {
      if (await auth.signUp(email, password)) await _verify(email);
      return;
    }
    try {
      await auth.signInWithPassword(email, password);
    } on AuthException catch (e) {
      if (e.code != 'email_not_confirmed') rethrow;
      try {
        await auth.resendSignupCode(email);
      } on AuthException {
        // Rate-limited (e.g. right after sign-up): the earlier code still works,
        // and the code screen has its own Resend.
      }
      await _verify(email);
    }
  });

  /// Signed up but not yet confirmed: hand over to the code screen.
  Future<void> _verify(String email) async {
    if (mounted) setState(() => _isLoading = false);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => VerifyEmailPage(email: email)),
    );
  }

  void _forgotPassword(String email) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResetPasswordPage(initialEmail: email),
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    // AuthGate's isGuest listener takes it from here (warms local category
    // state, then switches phases) — stay loading until this page is
    // replaced. No try/catch needed: this only ever writes to
    // SharedPreferences, nothing that can throw a user-facing error.
    await AuthService.instance.enterGuestMode();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return AuthPageScaffold(
      heading: _isSignUp ? 'Create your account' : 'Welcome back',
      subtext: 'Track expenses across devices',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginForm(
            isSignUp: _isSignUp,
            isLoading: _isLoading,
            onSubmit: _submit,
            onToggleMode: () => setState(() => _isSignUp = !_isSignUp),
            onForgotPassword: _forgotPassword,
          ),
          const SizedBox(height: AppSpacing.lg),
          SocialSignInButtons(
            isLoading: _isLoading,
            onGoogle: AppConfig.hasGoogle
                ? () => _run(auth.signInWithGoogle)
                : null,
            // Required on iOS by App Store guideline 4.8; skipped on
            // Android, where it would need a web redirect flow.
            onApple: defaultTargetPlatform == TargetPlatform.iOS
                ? () => _run(auth.signInWithApple)
                : null,
            onContinueAsGuest: _continueAsGuest,
          ),
        ],
      ),
    );
  }
}
