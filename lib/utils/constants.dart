/// Constants used throughout the app
class AppConstants {
  AppConstants._();

  /// Error messages
  static const String errorNotSignedIn = 'Not signed in. Please sign in to continue.';
  static const String errorFailedToLoadExpenses = 'Could not load expenses';
  static const String errorFailedToSaveExpense = 'Could not save expense';
  static const String errorFailedToUpdateExpense = 'Could not update expense';
  static const String errorFailedToDeleteExpense = 'Could not delete expense';
  static const String confirmDeleteExpense = 'Are you sure you want to delete this expense?';
  static const String expenseDeleted = 'Expense deleted successfully';
  static const String expenseUpdated = 'Expense updated successfully';
  static const String errorAppInitFailed = 'Unable to initialize the app.';
  static const String errorAppInitInstructions =
      'Copy config.dev.json.example to config.dev.json and run: '
      'python3 scripts/define_from_json.py config.dev.json run';

  /// Validation messages
  static const String validationEmailRequired = 'Enter your email';
  static const String validationEmailInvalid = 'Enter a valid email';
  static const String validationPasswordRequired = 'Enter your password';
  static const String validationPasswordTooShort = 'Password must be at least 6 characters';
  static const String validationNameRequired = 'Enter a name';
  static const String validationAmountRequired = 'Enter an amount';
  static const String validationAmountInvalid = 'Enter a valid number';

  /// UI text
  static const String noExpensesMessage = 'No expenses yet. Tap + to add one.';
  static const String signedInAsLabel = 'Signed in as';
}
