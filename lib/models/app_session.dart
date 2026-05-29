/// Signed-in user session from Auth0 (identity only; data lives in Supabase).
class AppSession {
  const AppSession({
    required this.userId,
    this.email,
    this.name,
    this.nickname,
    this.pictureUrl,
  });

  /// Auth0 subject (`sub` claim) — used as `user_id` in Supabase tables.
  final String userId;
  final String? email;
  final String? name;
  final String? nickname;
  final String? pictureUrl;

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (nickname != null && nickname!.trim().isNotEmpty) {
      return nickname!.trim();
    }
    return ProfileFallback.displayNameFromEmail(email ?? '');
  }
}

/// Display helpers without depending on Auth0 SDK types in models.
class ProfileFallback {
  ProfileFallback._();

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
}
