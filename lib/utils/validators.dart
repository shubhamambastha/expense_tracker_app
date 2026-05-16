import 'constants.dart';

/// Email validator
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppConstants.validationEmailRequired;
  }
  if (!value.contains('@')) {
    return AppConstants.validationEmailInvalid;
  }
  return null;
}

/// Password validator
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return AppConstants.validationPasswordRequired;
  }
  if (value.length < 6) {
    return AppConstants.validationPasswordTooShort;
  }
  return null;
}

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
