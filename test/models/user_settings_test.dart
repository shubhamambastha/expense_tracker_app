import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker_app/models/user_settings.dart';

void main() {
  group('UserSettings.fromMap onboarding_completed_at', () {
    test(
      'CRITICAL REGRESSION: missing/null column reads as null (pending), '
      'never defaults to "complete" implicitly',
      () {
        final settings = UserSettings.fromMap({
          'user_id': 'auth0|abc',
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
        'user_id': 'auth0|abc',
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
        'user_id': 'auth0|abc',
        'default_currency_code': 'USD',
        'preferences': {},
        'updated_at': '2027-01-01T00:00:00.000Z',
      });
      expect(settings.onboardingCompletedAt, isNull);
    });
  });
}
