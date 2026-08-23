import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../screens/auth/login_page.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/home/expense_home_page.dart';
import '../../services/auth_service.dart';
import '../../services/category_budget_service.dart';
import '../../services/category_catalog.dart';
import '../../services/income_category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../services/settings_preferences.dart';
import '../../services/deep_link_service.dart';
import '../../services/guest_migration_service.dart';
import '../../services/guest_store.dart';
import '../../services/splash_bootstrap.dart';
import '../dialogs/confirm_guest_migration_dialog.dart';
import '../../utils/snackbar_helper.dart';

/// [CategoryCatalog]/[IncomeCategoryCatalog].syncForUser take a userId
/// parameter that's structurally required but never actually read by the
/// underlying argument-less remote calls — any non-empty placeholder works.
const _kGuestSyncPlaceholder = 'guest';

enum _AuthPhase { splash, login, app }

/// Root gate: splash while restoring session, login when signed out, app when
/// signed in. Nothing else is reachable without a valid session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  _AuthPhase _phase = _AuthPhase.splash;

  SplashUiState _splashUiState = SplashUiState.loading;
  String _splashStatusMessage = SplashBootstrapStep.restoringSession.statusMessage;
  String? _splashErrorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(DeepLinkService.instance.start());
    AuthService.instance.session.addListener(_onSessionChange);
    AuthService.instance.isGuest.addListener(_onGuestChange);
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    setState(() {
      _splashUiState = SplashUiState.loading;
      _splashErrorMessage = null;
      _splashStatusMessage =
          SplashBootstrapStep.restoringSession.statusMessage;
    });

    try {
      final result = await SplashBootstrap.instance.run(
        onProgress: (progress) {
          if (!mounted || _phase != _AuthPhase.splash) return;
          setState(() {
            _splashStatusMessage = progress.statusMessage;
          });
        },
      );

      if (!mounted) return;
      await _applyBootstrapResult(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _splashUiState = SplashUiState.error;
        _splashErrorMessage = 'Unable to load app';
      });
    }
  }

  Future<void> _applyBootstrapResult(SplashBootstrapResult result) async {
    if (result.requiresBiometricUnlock) {
      // Biometric gate will live between splash and app in a later iteration.
    }

    final nextPhase = switch (result.destination) {
      SplashDestination.dashboard => _AuthPhase.app,
      SplashDestination.authentication => _AuthPhase.login,
      SplashDestination.onboarding => _AuthPhase.login,
    };

    setState(() => _phase = nextPhase);

    // A guest cold start also reaches `dashboard` but carries no userId
    // (see SplashBootstrap._warmGuestData) — still capture pending deep
    // links (e.g. the AddExpenseWidget launch intent) for them.
    if (nextPhase == _AuthPhase.app) {
      unawaited(DeepLinkService.instance.captureLinks());
    }

    if (result.userId != null) {
      if (result.syncDeferred) {
        unawaited(SplashBootstrap.instance.completeDeferredSync(result.userId!));
      }
    }
  }

  void _onSessionChange() {
    if (_phase == _AuthPhase.splash) return;

    final session = AuthService.instance.currentSession;
    if (session != null) {
      unawaited(_handleSignedIn(session.userId));
    } else {
      _clearUserScopedState();
      setState(() => _phase = _AuthPhase.login);
    }
  }

  Future<void> _handleSignedIn(String userId) async {
    await _maybeOfferGuestMigration(userId);
    await _syncUserPreferences(userId);
    if (!mounted || _phase == _AuthPhase.splash) return;
    setState(() => _phase = _AuthPhase.app);
    unawaited(DeepLinkService.instance.captureLinks());
  }

  /// Offers to import leftover local guest data the moment a real Auth0
  /// session lands — runs before [_syncUserPreferences] so the account's
  /// categories exist for name-matching during replay. A decline leaves
  /// [GuestStore] untouched; the same import can be re-run later from
  /// Settings (see `SettingsPage`'s guest-data section).
  Future<void> _maybeOfferGuestMigration(String userId) async {
    final hasData = await GuestStore.instance.hasMigratableData();
    if (!hasData || !mounted) return;

    final summary = await GuestMigrationService.instance.buildSummary();
    if (!mounted) return;
    final accepted = await showGuestMigrationDialog(context, summary: summary);
    if (!accepted || !mounted) return;

    final result = await GuestMigrationService.instance.migrate();
    if (!mounted) return;
    if (result.success) {
      SnackbarHelper.showSuccess(
        context,
        'Imported ${summary.transactionCount} transactions from guest mode',
      );
    } else {
      SnackbarHelper.showError(
        context,
        'Could not import your guest data — you can try again from Settings',
      );
    }
  }

  void _onGuestChange() {
    if (_phase == _AuthPhase.splash) return;
    if (AuthService.instance.isGuest.value) {
      unawaited(_handleGuestEntry());
    }
  }

  /// Warms the same category/budget singletons a real sign-in warms —
  /// their remote calls are already guest-branched inside [SupabaseService],
  /// so this reloads them from [GuestStore] instead of Supabase.
  Future<void> _handleGuestEntry() async {
    await CategoryCatalog.instance.syncForUser(_kGuestSyncPlaceholder);
    await IncomeCategoryCatalog.instance.syncForUser(_kGuestSyncPlaceholder);
    await CategoryBudgetService.instance.refresh();
    if (!mounted || _phase == _AuthPhase.splash) return;
    setState(() => _phase = _AuthPhase.app);
    unawaited(DeepLinkService.instance.captureLinks());
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
    AuthService.instance.session.removeListener(_onSessionChange);
    AuthService.instance.isGuest.removeListener(_onGuestChange);
    unawaited(DeepLinkService.instance.dispose());
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
    if (AuthService.instance.isGuest.value) {
      // No Auth0 session to close. GuestStore data is intentionally left
      // untouched — re-entering guest mode later resumes where they left
      // off, same as declining the migration offer does.
      await AuthService.instance.exitGuestMode();
    } else {
      await AuthService.instance.logout();
    }
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
          _AuthPhase.splash => SplashScreen(
              key: const ValueKey('splash'),
              uiState: _splashUiState,
              statusMessage: _splashStatusMessage,
              errorMessage: _splashErrorMessage ?? 'Unable to load app',
              onRetry: _bootstrap,
            ),
          _AuthPhase.login => const LoginPage(key: ValueKey('login')),
          _AuthPhase.app => ExpenseHomePage(
              key: const ValueKey('app'),
              onSignOut: _signOut,
            ),
        },
      ),
    );
  }
}
