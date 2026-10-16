import 'constants.dart';

/// Matches the minimum set in Supabase → Auth → Providers → Email.
const minPasswordLength = 8;

/// Email validator
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return AppConstants.validationEmailRequired;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return AppConstants.validationEmailInvalid;
  }
  return null;
}

/// Sign-in password: any length (the minimum only applies to new passwords).
String? validatePassword(String? value) =>
    (value ?? '').isEmpty ? AppConstants.validationPasswordRequired : null;

/// Sign-up / reset password.
String? validateNewPassword(String? value) =>
    (value ?? '').length < minPasswordLength
    ? 'Use at least $minPasswordLength characters'
    : null;

/// Emailed sign-up / reset code. Supabase's OTP length is configurable (6 by default).
String? validateCode(String? value) =>
    RegExp(r'^\d{6,10}$').hasMatch(value?.trim() ?? '')
    ? null
    : AppConstants.validationCodeInvalid;

/// Expense name validator
String? validateExpenseName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppConstants.validationNameRequired;
  }
  return null;
}

/// Amount validator
String? validateAmount(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppConstants.validationAmountRequired;
  }
  if (double.tryParse(value) == null) {
    return AppConstants.validationAmountInvalid;
  }
  return null;
}
