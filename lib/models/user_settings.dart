class UserSettings {
  const UserSettings({
    required this.userId,
    required this.defaultCurrencyCode,
    this.updatedAt,
  });

  final String userId;
  final String defaultCurrencyCode;
  final DateTime? updatedAt;

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      userId: map['user_id'] as String,
      defaultCurrencyCode:
          map['default_currency_code'] as String? ?? 'USD',
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'default_currency_code': defaultCurrencyCode,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
