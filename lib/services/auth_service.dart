import 'dart:async';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/app_session.dart';
import '../utils/app_config.dart';
import '../utils/auth0_urls.dart';

/// Auth0 Universal Login — session storage and token access for Supabase.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  late final Auth0 _auth0;
  bool _initialized = false;

  final ValueNotifier<AppSession?> session = ValueNotifier<AppSession?>(null);

  Future<void> init() async {
    if (_initialized) return;
    final domain = AppConfig.auth0Domain;
    final clientId = AppConfig.auth0ClientId;
    if (domain.isEmpty || clientId.isEmpty) {
      throw Exception(
        'Missing AUTH0_DOMAIN or AUTH0_CLIENT_ID. Provide via --dart-define',
      );
    }
    _auth0 = Auth0(domain, clientId);
    _initialized = true;
    await refreshSession();
  }

  Auth0 get auth0 {
    if (!_initialized) {
      throw StateError('AuthService.init() must be called first');
    }
    return _auth0;
  }

  AppSession? get currentSession => session.value;

  Future<bool> hasValidCredentials() async {
    if (!_initialized) return false;
    return _auth0.credentialsManager.hasValidCredentials();
  }

  Future<Credentials> credentials() async {
    return _auth0.credentialsManager.credentials();
  }

  Future<void> refreshSession() async {
    if (!_initialized) {
      session.value = null;
      return;
    }
    try {
      if (!await hasValidCredentials()) {
        session.value = null;
        return;
      }
      final creds = await credentials();
      session.value = _sessionFromCredentials(creds);
    } catch (_) {
      session.value = null;
    }
  }

  /// Defaults to a custom URL scheme on every platform (no Android App Links /
  /// iOS Universal Links verification needed) unless [AppConfig.auth0UseHttps] opts in.
  WebAuthentication _webAuthentication() {
    if (_useHttpsCallbacks) {
      return auth0.webAuthentication();
    }
    return auth0.webAuthentication(scheme: AppConfig.auth0CallbackScheme);
  }

  bool get _useHttpsCallbacks => AppConfig.auth0UseHttps;

  /// Explicit redirect for iOS/macOS custom scheme (must match Auth0 dashboard + Info.plist).
  String? get _customSchemeRedirectUrl =>
      Auth0Urls.customSchemeCallback(defaultTargetPlatform);

  Future<AppSession> login() async {
    try {
      final webAuth = _webAuthentication();
      final creds = _useHttpsCallbacks
          ? await webAuth.login(useHTTPS: true)
          : await webAuth.login(redirectUrl: _customSchemeRedirectUrl);
      final appSession = _sessionFromCredentials(creds);
      session.value = appSession;
      return appSession;
    } on WebAuthenticationException catch (e) {
      if (e.code == 'USER_CANCELLED') {
        throw AuthLoginCancelledException();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    if (!_initialized) return;
    try {
      final webAuth = _webAuthentication();
      if (_useHttpsCallbacks) {
        await webAuth.logout(useHTTPS: true);
      } else {
        await webAuth.logout(returnTo: _customSchemeRedirectUrl);
      }
    } on WebAuthenticationException {
      // Still clear local session if browser logout fails.
    } finally {
      session.value = null;
    }
  }

  AppSession _sessionFromCredentials(Credentials creds) {
    final user = creds.user;
    return AppSession(
      userId: user.sub,
      email: user.email,
      name: user.name,
      nickname: user.nickname,
      pictureUrl: user.pictureUrl?.toString(),
    );
  }
}

/// User dismissed the Auth0 login browser.
class AuthLoginCancelledException implements Exception {
  @override
  String toString() => 'Login was cancelled';
}
