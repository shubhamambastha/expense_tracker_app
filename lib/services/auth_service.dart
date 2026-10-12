import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_session.dart';
import '../utils/app_config.dart';
import '../utils/constants.dart';

/// Supabase Auth — email + password, native Google/Apple, session storage
/// and token access for the API.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _kIsGuestKey = 'guest.is_active';

  // SDK errors (GoogleSignInException, SignInWithAppleAuthorizationException) read like stack
  // dumps in a snackbar; SnackbarHelper shows an AuthException's message as-is.
  static const _googleFailed =
      "Couldn't sign in with Google. Please try again.";
  static const _appleFailed = "Couldn't sign in with Apple. Please try again.";

  bool _initialized = false;
  Future<void>? _googleInit;
  AppSession? _current;

  /// Notifies only when the signed-in *user* changes (sign in, sign out),
  /// never on token refreshes or profile edits: AuthGate re-runs its whole
  /// sign-in handling (sync, migration offer) on every notification. Read
  /// the latest profile through [currentSession].
  final ValueNotifier<AppSession?> session = ValueNotifier<AppSession?>(null);

  /// True while the user is using the app without a Supabase session — all
  /// data access routes to on-device storage instead of the API. Persisted
  /// so it survives a process kill (checked by [SplashBootstrap] at cold
  /// start, same as [session] is restored from secure storage).
  final ValueNotifier<bool> isGuest = ValueNotifier<bool>(false);

  GoTrueClient get _auth => Supabase.instance.client.auth;

  Future<void> init() async {
    if (_initialized) return;
    if (!AppConfig.hasSupabase) {
      throw Exception(
        'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. Provide via --dart-define',
      );
    }
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: _SecureSessionStorage(),
        // Email codes and native Google/Apple sheets: no auth deep links.
        detectSessionInUri: false,
      ),
    );
    _initialized = true;
    await _loadGuestFlag();
    setUser(_auth.currentUser);
    _auth.onAuthStateChange.listen(
      (state) => setUser(state.session?.user),
      // Refresh failures (e.g. offline) arrive here too; the session stays as it was.
      onError: (_) {},
    );
  }

  Future<void> _loadGuestFlag() async {
    final prefs = await SharedPreferences.getInstance();
    isGuest.value = prefs.getBool(_kIsGuestKey) ?? false;
  }

  /// Enters guest mode: no Supabase session, all data local. Persisted so a
  /// cold restart lands back in the app instead of at login.
  Future<void> enterGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsGuestKey, true);
    isGuest.value = true;
  }

  /// Leaves guest mode without touching any locally stored guest data —
  /// callers decide separately whether to keep, migrate, or discard it.
  Future<void> exitGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsGuestKey);
    isGuest.value = false;
  }

  AppSession? get currentSession => _current;

  /// Called for every auth event; public only so tests can drive it.
  @visibleForTesting
  void setUser(User? user) {
    final next = user == null ? null : _sessionFromUser(user);
    final changed = next?.userId != _current?.userId;
    _current = next;
    if (changed) session.value = next;
  }

  /// Bearer token for the API. The SDK refreshes ahead of expiry on its own;
  /// [forceRefresh] is the one retry after a 401.
  Future<String> accessToken({bool forceRefresh = false}) async {
    var current = _auth.currentSession;
    if (current == null) throw Exception(AppConstants.errorNotSignedIn);
    if (forceRefresh || current.isExpired) {
      current = (await _auth.refreshSession()).session ?? current;
    }
    return current.accessToken;
  }

  // --- Email + password ---------------------------------------------------

  Future<void> signInWithPassword(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  /// Returns true when the account still needs its emailed 6-digit code
  /// ("Confirm email" on); false when Supabase signed the user straight in.
  Future<bool> signUp(String email, String password) async {
    final res = await _auth.signUp(email: email, password: password);
    // An already-registered email gets a fake user with no identities (anti-enumeration) and no
    // email, so the code screen would wait forever.
    if (res.user?.identities?.isEmpty ?? false) {
      throw const AuthException(
        'An account with this email already exists. Sign in instead.',
      );
    }
    return res.session == null;
  }

  Future<void> verifyEmailCode(String email, String code) =>
      _auth.verifyOTP(email: email, token: code, type: OtpType.signup);

  Future<void> resendSignupCode(String email) =>
      _auth.resend(email: email, type: OtpType.signup);

  Future<void> sendPasswordReset(String email) =>
      _auth.resetPasswordForEmail(email);

  /// The recovery code signs the user in; the new password is then set on
  /// that session. The code is single-use, so a retry after a failed
  /// password update (e.g. same_password) skips straight to the update.
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final verified =
        _auth.currentUser?.email?.toLowerCase() == email.toLowerCase();
    if (!verified) {
      await _auth.verifyOTP(email: email, token: code, type: OtpType.recovery);
    }
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  // --- Native social sign-in ----------------------------------------------

  /// GoogleSignIn.initialize() must run exactly once per process.
  Future<void> _ensureGoogle() => _googleInit ??= GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? AppConfig.googleIosClientId
            : null,
        serverClientId: AppConfig.googleWebClientId,
      );

  Future<void> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    await _ensureGoogle();
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthLoginCancelledException();
      }
      throw const AuthException(_googleFailed);
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthException(_googleFailed);
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  /// iOS only (the login screen hides it elsewhere).
  Future<void> signInWithApple() async {
    final rawNonce = _auth.generateRawNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthLoginCancelledException();
      }
      throw const AuthException(_appleFailed);
    }
    final idToken = credential.identityToken;
    if (idToken == null) throw const AuthException(_appleFailed);
    await _auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
    // Apple shares the name only on the very first authorization, and never
    // inside the ID token, so store it now or lose it.
    final name = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().join(' ').trim();
    if (name.isNotEmpty) {
      try {
        await _auth.updateUser(UserAttributes(data: {'full_name': name}));
      } catch (_) {
        // Best-effort: the user is already signed in, and onboarding asks for a name anyway.
      }
    }
  }

  Future<void> logout() async {
    if (!_initialized) return;
    try {
      // Without this the Google sheet silently reuses the last account.
      // Also after a cold start, when Google hasn't been touched this process.
      if (AppConfig.hasGoogle) {
        await _ensureGoogle();
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {
      // Signing out of Supabase below is what matters.
    }
    try {
      await _auth.signOut();
    } catch (_) {
      // The local session is already gone; a failed server-side revoke (e.g.
      // offline) only leaves the old refresh token to expire on its own.
    } finally {
      setUser(null);
    }
  }

  AppSession _sessionFromUser(User user) {
    final meta = user.userMetadata ?? const {};
    String? text(String key) =>
        meta[key] is String ? meta[key] as String : null;
    return AppSession(
      userId: user.id,
      email: user.email,
      // full_name/name from Google, full_name from Apple (set above).
      name: text('full_name') ?? text('name'),
      pictureUrl: text('avatar_url') ?? text('picture'),
    );
  }
}

/// Keeps the Supabase session (including the refresh token) in the iOS
/// Keychain / Android Keystore instead of the SDK's default SharedPreferences.
class _SecureSessionStorage extends LocalStorage {
  const _SecureSessionStorage();

  // first_unlock: refresh-token rotations that land while the phone is locked
  // (background refresh) must still persist, or the next launch signs out.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _key = 'supabase.session';

  @override
  Future<void> initialize() async {}

  // supabase_flutter doesn't guard these during initialize(): a keychain error
  // would fail every launch. Drop the broken entry and start signed out.
  @override
  Future<bool> hasAccessToken() async {
    try {
      return await _storage.containsKey(key: _key);
    } catch (_) {
      await removePersistedSession().catchError((_) {});
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      await removePersistedSession().catchError((_) {});
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}

/// User dismissed the Google or Apple sign-in sheet.
class AuthLoginCancelledException implements Exception {
  @override
  String toString() => 'Login was cancelled';
}
