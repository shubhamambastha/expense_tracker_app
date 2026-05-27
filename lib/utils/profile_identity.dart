import 'package:supabase_flutter/supabase_flutter.dart';

/// Helpers for deriving profile identity from Supabase Auth + local prefs.
class ProfileIdentity {
  ProfileIdentity._();

  static String emailFor(User? user) =>
      user?.email?.trim().isNotEmpty == true ? user!.email!.trim() : 'Unknown user';

  static bool isGoogleAuthUser(User? user) {
    if (user == null) return false;
    final provider = user.appMetadata['provider'];
    if (provider == 'google') return true;
    final identities = user.identities;
    if (identities == null) return false;
    return identities.any((i) => i.provider == 'google');
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

  static String? metadataDisplayName(User? user) {
    final raw = user?.userMetadata?['display_name'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  static String? metadataPhone(User? user) {
    final raw = user?.userMetadata?['phone'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }
}
