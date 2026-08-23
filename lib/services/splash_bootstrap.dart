import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'category_budget_service.dart';
import 'category_catalog.dart';
import 'currency_settings.dart';
import 'income_category_catalog.dart';
import 'settings_preferences.dart';
import 'auth_service.dart';

/// Where the splash flow should navigate once bootstrap completes.
enum SplashDestination {
  dashboard,
  authentication,

  /// Reserved for a future first-launch experience.
  onboarding,
}

/// Discrete startup steps surfaced to the splash UI.
enum SplashBootstrapStep {
  restoringSession,
  initializingLocal,
  checkingSync,
  loadingPreferences,
}

extension SplashBootstrapStepMessage on SplashBootstrapStep {
  String get statusMessage {
    switch (this) {
      case SplashBootstrapStep.restoringSession:
        return 'Restoring your session…';
      case SplashBootstrapStep.initializingLocal:
        return 'Preparing your workspace…';
      case SplashBootstrapStep.checkingSync:
        return 'Checking sync…';
      case SplashBootstrapStep.loadingPreferences:
        return 'Loading your preferences…';
    }
  }
}

/// Lightweight progress update for splash UI binding.
class SplashBootstrapProgress {
  const SplashBootstrapProgress({required this.step});

  final SplashBootstrapStep step;

  String get statusMessage => step.statusMessage;
}

/// Outcome of the modular splash bootstrap pipeline.
class SplashBootstrapResult {
  const SplashBootstrapResult({
    required this.destination,
    this.userId,
    this.usedOfflineCache = false,
    this.syncDeferred = false,
    this.requiresBiometricUnlock = false,
  });

  final SplashDestination destination;
  final String? userId;

  /// True when navigation proceeded using locally cached auth/data.
  final bool usedOfflineCache;

  /// True when remote sync was skipped or timed out and should continue later.
  final bool syncDeferred;

  /// Future-ready flag for a post-splash biometric unlock step.
  final bool requiresBiometricUnlock;
}

/// Orchestrates startup: session restore, local cache, sync checks, routing.
///
/// Designed to stay fast and offline-first — network work is bounded and
/// non-blocking for navigation.
class SplashBootstrap {
  SplashBootstrap._();

  static final SplashBootstrap instance = SplashBootstrap._();

  static const _syncTimeout = Duration(milliseconds: 2500);
  static const _kOnboardingCompleteKey = 'onboarding_complete';

  /// [CategoryCatalog]/[IncomeCategoryCatalog].syncForUser take a userId
  /// parameter that only ever gets forwarded to argument-less remote calls
  /// (`SupabaseService.ensureDefaultCategories()`, etc.) — it's structurally
  /// required but never actually read. Any non-empty placeholder is safe.
  static const _guestSyncPlaceholder = 'guest';

  Future<SplashBootstrapResult> run({
    void Function(SplashBootstrapProgress progress)? onProgress,
    Duration syncTimeout = _syncTimeout,
  }) async {
    void report(SplashBootstrapStep step) {
      onProgress?.call(SplashBootstrapProgress(step: step));
    }

    report(SplashBootstrapStep.restoringSession);
    final session = AuthService.instance.currentSession;

    report(SplashBootstrapStep.initializingLocal);
    await _ensureLocalStoresReady();

    if (session == null) {
      if (AuthService.instance.isGuest.value) {
        report(SplashBootstrapStep.checkingSync);
        await _warmGuestData();
        return const SplashBootstrapResult(destination: SplashDestination.dashboard);
      }
      return SplashBootstrapResult(
        destination: await _resolveLoggedOutDestination(),
      );
    }

    report(SplashBootstrapStep.checkingSync);
    report(SplashBootstrapStep.loadingPreferences);

    final syncDeferred = await _warmUserData(
      session.userId,
      syncTimeout: syncTimeout,
    );

    final requiresBiometric = await _checkBiometricUnlockRequired();

    return SplashBootstrapResult(
      destination: SplashDestination.dashboard,
      userId: session.userId,
      usedOfflineCache: syncDeferred,
      syncDeferred: syncDeferred,
      requiresBiometricUnlock: requiresBiometric,
    );
  }

  /// Completes preference/category sync after the app is already visible.
  Future<void> completeDeferredSync(String userId) {
    return _warmUserData(userId, syncTimeout: const Duration(seconds: 30));
  }

  Future<void> _ensureLocalStoresReady() async {
    await Future.wait([
      CurrencySettings.instance.load(),
      SettingsPreferences.instance.load(),
    ]);
  }

  Future<bool> _warmUserData(
    String userId, {
    required Duration syncTimeout,
  }) async {
    try {
      await Future.wait([
        CurrencySettings.instance.syncForUser(userId),
        SettingsPreferences.instance.syncForUser(userId),
        CategoryCatalog.instance.syncForUser(userId),
        IncomeCategoryCatalog.instance.syncForUser(userId),
        CategoryBudgetService.instance.refresh(),
      ]).timeout(syncTimeout);
      return false;
    } catch (error) {
      debugPrint('SplashBootstrap: sync deferred ($error)');
      return true;
    }
  }

  /// Loads guest category/budget state from [GuestStore] (via the already
  /// guest-branched [SupabaseService] methods). Unlike [_warmUserData] this
  /// is purely local — no timeout needed, nothing can hang. `CurrencySettings`
  /// and `SettingsPreferences` need no guest-specific call here: [load]
  /// already restored them from their session-independent local cache, and
  /// their remote-sync paths already no-op when there's no Auth0 session.
  Future<void> _warmGuestData() async {
    try {
      await Future.wait([
        CategoryCatalog.instance.syncForUser(_guestSyncPlaceholder),
        IncomeCategoryCatalog.instance.syncForUser(_guestSyncPlaceholder),
        CategoryBudgetService.instance.refresh(),
      ]);
    } catch (error) {
      debugPrint('SplashBootstrap: guest warm-up failed ($error)');
    }
  }

  Future<SplashDestination> _resolveLoggedOutDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool(_kOnboardingCompleteKey) ?? true;
    if (!onboardingComplete) {
      return SplashDestination.onboarding;
    }
    return SplashDestination.authentication;
  }

  /// Placeholder for a future biometric gate (reads local security prefs).
  Future<bool> _checkBiometricUnlockRequired() async {
    return false;
  }
}
