import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../screens/auth/login_page.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/home/expense_home_page.dart';
import '../../services/category_budget_service.dart';
import '../../services/category_catalog.dart';
import '../../services/income_category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../services/settings_preferences.dart';
import '../../services/supabase_service.dart';

enum _AuthPhase { splash, login, app }

/// Root gate: splash while restoring session, login when signed out, app when
/// signed in. Nothing else is reachable without a valid session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _minSplashDuration = Duration(milliseconds: 1200);

  _AuthPhase _phase = _AuthPhase.splash;
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        SupabaseService.authStateChanges.listen(_onAuthStateChange);
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final splashDelay = Future<void>.delayed(_minSplashDuration);
    final user = SupabaseService.currentUser;

    if (user != null) {
      await _syncUserPreferences(user.id);
    }

    await splashDelay;
    if (!mounted) return;

    setState(() {
      _phase = user != null ? _AuthPhase.app : _AuthPhase.login;
    });
  }

  void _onAuthStateChange(dynamic _) {
    if (_phase == _AuthPhase.splash) return;

    final user = SupabaseService.currentUser;
    if (user != null) {
      unawaited(_handleSignedIn(user.id));
    } else {
      _clearUserScopedState();
      setState(() => _phase = _AuthPhase.login);
    }
  }

  Future<void> _handleSignedIn(String userId) async {
    await _syncUserPreferences(userId);
    if (!mounted || _phase == _AuthPhase.splash) return;
    setState(() => _phase = _AuthPhase.app);
  }

  void _clearUserScopedState() {
    CurrencySettings.instance.onSignedOut();
    SettingsPreferences.instance.onSignedOut();
    CategoryCatalog.instance.onSignedOut();
    IncomeCategoryCatalog.instance.onSignedOut();
    CategoryBudgetService.instance.onSignedOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _syncUserPreferences(String userId) async {
    await CurrencySettings.instance.syncForUser(userId);
    await SettingsPreferences.instance.syncForUser(userId);
    await CategoryCatalog.instance.syncForUser(userId);
    await IncomeCategoryCatalog.instance.syncForUser(userId);
    await CategoryBudgetService.instance.refresh();
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    _clearUserScopedState();
    if (!mounted) return;
    setState(() => _phase = _AuthPhase.login);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase == _AuthPhase.app,
      child: AnimatedSwitcher(
        duration: AppDurations.page,
        switchInCurve: AppCurves.emphasized,
        switchOutCurve: Curves.easeIn,
        child: switch (_phase) {
          _AuthPhase.splash => const SplashScreen(key: ValueKey('splash')),
          _AuthPhase.login => LoginPage(
              key: const ValueKey('login'),
              onSignedIn: () async {
                final user = SupabaseService.currentUser;
                if (user != null) {
                  await _handleSignedIn(user.id);
                }
              },
            ),
          _AuthPhase.app => ExpenseHomePage(
              key: const ValueKey('app'),
              onSignOut: _signOut,
            ),
        },
      ),
    );
  }
}
