import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';
import 'auth_service.dart';
import 'guest_store.dart';
import 'supabase_service.dart';

/// Tracks whether the post-login onboarding wizard has been completed or
/// skipped — distinct from `SplashBootstrap`'s unrelated, dead
/// `onboarding_complete` pre-login key (see
/// docs/designs/post-login-onboarding.md). Local-first for real accounts:
/// the SharedPreferences flag is the source of truth for whether the wizard
/// re-shows on this device; the remote column write is best-effort. Guest
/// accounts use their own fully-local `GuestStore` flag.
class OnboardingWizardStatus {
  OnboardingWizardStatus._();

  static final OnboardingWizardStatus instance = OnboardingWizardStatus._();

  static const _kLocalComplete = 'financial_profile_onboarding_complete';

  static bool get _isGuest => AuthService.instance.isGuest.value;

  /// True if the wizard should be skipped. Checks the local cache first
  /// (no network); a real account falls back to the remote column only when
  /// the local cache has never been set (fresh install, reinstall, or a
  /// second device).
  Future<bool> isComplete() async {
    if (!FeatureFlags.postLoginOnboardingEnabled) return true;
    if (_isGuest) return GuestStore.instance.isOnboardingComplete();

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kLocalComplete) == true) return true;

    final remote = await SupabaseService.fetchOnboardingCompletedAt();
    if (remote != null) {
      await prefs.setBool(_kLocalComplete, true);
      return true;
    }
    return false;
  }

  /// Marks the wizard complete (finished or explicitly skipped). Writes the
  /// local cache synchronously so the wizard never re-shows on this device
  /// even if the remote write fails; the remote write is fire-and-forget
  /// best-effort (Open Question #8 — no step or completion write blocks
  /// reaching the dashboard).
  Future<void> markComplete() async {
    if (_isGuest) {
      await GuestStore.instance.setOnboardingComplete();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLocalComplete, true);
    unawaited(SupabaseService.markOnboardingComplete());
  }

  static const _kIncomeStepDone = 'onboarding_wizard_income_step_done';

  /// Idempotent-resume guard (Open Design Question D2): if the app is
  /// killed after the income step already created a real transaction but
  /// before the wizard's overall completion flag is set, a naive
  /// restart-at-step-1 would re-offer that step and create a duplicate.
  /// Local-only and device-scoped — only matters while a wizard run is
  /// genuinely in flight; once [markComplete] runs, nothing reads it again.
  /// Recurring doesn't need this guard: each add is an explicit per-tap
  /// user action (list of kinds on the step itself), not an auto-triggered
  /// push, so re-visiting the step and adding another item is the intended
  /// flow, not a duplicate-risk to prevent.
  Future<bool> isIncomeStepDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIncomeStepDone) ?? false;
  }

  Future<void> markIncomeStepDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIncomeStepDone, true);
  }
}
