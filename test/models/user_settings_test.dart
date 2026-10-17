import 'package:flutter_test/flutter_test.dart';

import 'package:jebbo/models/user_settings.dart';

void main() {
  group('UserSettings.fromMap onboarding_completed_at', () {
    test(
      'CRITICAL REGRESSION: missing/null column reads as null (pending), '
      'never defaults to "complete" implicitly',
      () {
        final settings = UserSettings.fromMap({
          'user_id': '5f0c6a8e-1b2d-4c3e-9f40-a1b2c3d4e5f6',
          'default_currency_code': 'USD',
          'preferences': {},
          'updated_at': '2027-01-01T00:00:00.000Z',
          'onboarding_completed_at': null,
        });
        expect(settings.onboardingCompletedAt, isNull);
      },
    );

    test('a set timestamp round-trips correctly', () {
      final settings = UserSettings.fromMap({
        'user_id': '5f0c6a8e-1b2d-4c3e-9f40-a1b2c3d4e5f6',
        'default_currency_code': 'USD',
        'preferences': {},
        'updated_at': '2027-01-01T00:00:00.000Z',
        'onboarding_completed_at': '2027-01-15T12:00:00.000Z',
      });
      expect(
        settings.onboardingCompletedAt,
        DateTime.parse('2027-01-15T12:00:00.000Z'),
      );
    });

    test('key entirely absent from the map (legacy row) reads as null', () {
      final settings = UserSettings.fromMap({
        'user_id': '5f0c6a8e-1b2d-4c3e-9f40-a1b2c3d4e5f6',
        'default_currency_code': 'USD',
        'preferences': {},
        'updated_at': '2027-01-01T00:00:00.000Z',
      });
      expect(settings.onboardingCompletedAt, isNull);
    });
  });
}
