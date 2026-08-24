class UserSettings {
  const UserSettings({
    required this.userId,
    required this.defaultCurrencyCode,
    this.preferences = const {},
    this.updatedAt,
    this.onboardingCompletedAt,
  });

  final String userId;
  final String defaultCurrencyCode;

  /// App settings blob (keys mirror `SettingsPreferences` SharedPreferences).
  final Map<String, dynamic> preferences;

  final DateTime? updatedAt;

  /// When the post-login onboarding wizard was completed or skipped.
  /// Null means onboarding is pending (shows the wizard) — see
  /// `sql/20260824_onboarding_completed_at.sql` for the backfill that keeps
  /// every pre-existing account out of the gate.
  final DateTime? onboardingCompletedAt;

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    final raw = map['preferences'];
    Map<String, dynamic> prefs = {};
    if (raw is Map) {
      prefs = Map<String, dynamic>.from(raw);
    }
    return UserSettings(
      userId: map['user_id'] as String,
      defaultCurrencyCode:
          map['default_currency_code'] as String? ?? 'USD',
      preferences: prefs,
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(map['updated_at'] as String),
      onboardingCompletedAt: map['onboarding_completed_at'] == null
          ? null
          : DateTime.parse(map['onboarding_completed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'default_currency_code': defaultCurrencyCode,
      'preferences': preferences,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
