import '../models/app_session.dart';
import '../services/auth_service.dart';

/// Helpers for deriving profile identity from Auth0 session + local prefs.
class ProfileIdentity {
  ProfileIdentity._();

  static AppSession? get _session => AuthService.instance.currentSession;

  static String emailFor([AppSession? session]) {
    final s = session ?? _session;
    final email = s?.email?.trim();
    return email != null && email.isNotEmpty ? email : 'Unknown user';
  }

  /// Falls back to capitalized email local-part when no stored name exists.
  static String displayNameFromEmail(String email) {
    if (email.isEmpty || email == 'Unknown user') return 'Your profile';
    final at = email.indexOf('@');
    if (at <= 0) return email;
    final local = email.substring(0, at);
    if (local.isEmpty) return email;
    return local[0].toUpperCase() + local.substring(1);
  }

  static String initialFor(String name, String email) {
    final source = name.trim().isNotEmpty ? name : email;
    if (source.isEmpty || source == 'Unknown user') return '?';
    return source[0].toUpperCase();
  }

  static String? sessionDisplayName([AppSession? session]) {
    final s = session ?? _session;
    if (s == null) return null;
    final name = s.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    final nick = s.nickname?.trim();
    if (nick != null && nick.isNotEmpty) return nick;
    return null;
  }
}
