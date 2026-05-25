import '../models/transaction_draft.dart';

/// Dynamic copy and smart defaults for the income Add Transaction flow.
class IncomeFlowHelpers {
  IncomeFlowHelpers._();

  static const defaultCategory = 'Salary';

  /// Label for the source / payer field based on income category.
  static String payerFieldLabel(String? categoryName) {
    switch (categoryName) {
      case 'Salary':
        return 'Employer';
      case 'Freelance':
        return 'Client';
      case 'Refund':
        return 'Refund source';
      case 'Gift':
        return 'From';
      case 'Bonus':
        return 'Source';
      case 'Cashback':
        return 'From';
      case 'Investment':
        return 'Source';
      case 'Rental':
        return 'Tenant / source';
      default:
        return 'Source';
    }
  }

  static String payerFieldHint(String? categoryName) {
    switch (categoryName) {
      case 'Salary':
        return 'e.g. Company XYZ';
      case 'Freelance':
        return 'e.g. Acme Corp';
      case 'Refund':
        return 'e.g. Amazon';
      case 'Gift':
        return 'e.g. Rahul';
      case 'Cashback':
        return 'e.g. Axis Ace';
      default:
        return 'Who sent this?';
    }
  }

  static String noteFieldHint(String? categoryName) {
    switch (categoryName) {
      case 'Salary':
        return 'e.g. April salary';
      case 'Freelance':
        return 'e.g. Client payment for website';
      case 'Refund':
        return 'e.g. Refund for cancelled order';
      default:
        return 'Add a note (optional)';
    }
  }

  /// Income-specific reminder subtitle (shown inside recurring section).
  static String recurringReminderHint(String? categoryName) {
    if (categoryName == 'Salary') {
      return 'Remind before expected salary · notify if missing';
    }
    return 'Remind before expected payment · notify if not received';
  }

  /// Apply category-driven recurring defaults (e.g. salary → monthly).
  static RecurringConfig applyCategoryRecurringDefaults({
    required String? categoryName,
    required RecurringConfig current,
  }) {
    if (categoryName == 'Salary' && !current.enabled) {
      return current.copyWith(frequency: RecurrenceFrequency.monthly);
    }
    if (categoryName == 'Rental' && !current.enabled) {
      return current.copyWith(frequency: RecurrenceFrequency.monthly);
    }
    return current;
  }

  /// Filter payer suggestions relevant to the active category.
  static List<String> filterPayerSuggestions({
    required String? categoryName,
    required List<String> allPayers,
    int limit = 6,
  }) {
    if (allPayers.isEmpty) return const [];
    return allPayers.take(limit).toList();
  }

  static String suggestionDisplayLabel({
    required String category,
    required String payer,
  }) {
    if (payer.trim().isEmpty) return category;
    return '$category · $payer';
  }
}
