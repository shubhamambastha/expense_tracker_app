import 'package:flutter/foundation.dart';

import 'app_config.dart';

/// Auth0 redirect URLs for iOS/macOS custom URL scheme login (see docs/auth0_setup.md).
class Auth0Urls {
  Auth0Urls._();

  /// `scheme://domain/ios|macos/scheme/callback` — must match Auth0 Allowed Callback URLs.
  static String? customSchemeCallback(TargetPlatform platform) {
    if (platform != TargetPlatform.iOS && platform != TargetPlatform.macOS) {
      return null;
    }
    final domain = AppConfig.auth0Domain;
    final scheme = AppConfig.auth0CallbackScheme;
    if (domain.isEmpty || scheme.isEmpty) return null;

    final segment = platform == TargetPlatform.iOS ? 'ios' : 'macos';
    return '$scheme://$domain/$segment/$scheme/callback';
  }
}
