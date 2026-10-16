import 'package:expense_tracker_app/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email validator accepts addresses and rejects junk', () {
    expect(validateEmail(' me@example.com '), isNull);
    expect(validateEmail(''), isNotNull);
    expect(validateEmail('me@example'), isNotNull);
    expect(validateEmail('not an email'), isNotNull);
  });

  test(
    'sign-in passwords only need to be present; new ones need the Supabase minimum',
    () {
      expect(validatePassword('x'), isNull);
      expect(validatePassword(''), isNotNull);
      expect(validateNewPassword('x' * minPasswordLength), isNull);
      expect(validateNewPassword('x' * (minPasswordLength - 1)), isNotNull);
    },
  );

  test('email codes are 6–10 digits', () {
    expect(validateCode('123456'), isNull);
    expect(validateCode(' 12345678 '), isNull);
    expect(validateCode('12345'), isNotNull);
    expect(validateCode('12a456'), isNotNull);
  });
}
