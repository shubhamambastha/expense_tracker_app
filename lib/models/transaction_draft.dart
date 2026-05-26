/// What the user is recording — maps to `transactions.kind`.
enum TransactionKind { expense, income, transfer }

extension TransactionKindX on TransactionKind {
  String get label {
    switch (this) {
      case TransactionKind.expense:
        return 'Expense';
      case TransactionKind.income:
        return 'Income';
      case TransactionKind.transfer:
        return 'Transfer';
    }
  }
}

/// How often a recurring transaction repeats.
enum RecurrenceFrequency { daily, weekly, monthly, quarterly, yearly, custom }

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String get label {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.quarterly:
        return 'Quarterly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
      case RecurrenceFrequency.custom:
        return 'Custom';
    }
  }
}

/// How early to remind the user before a recurring charge.
enum ReminderTiming { sameDay, oneDayBefore, twoDaysBefore, oneWeekBefore }

extension ReminderTimingX on ReminderTiming {
  String get label {
    switch (this) {
      case ReminderTiming.sameDay:
        return 'On due day';
      case ReminderTiming.oneDayBefore:
        return '1 day before';
      case ReminderTiming.twoDaysBefore:
        return '2 days before';
      case ReminderTiming.oneWeekBefore:
        return '1 week before';
    }
  }
}

/// Recurring configuration captured on the Add Transaction screen.
class RecurringConfig {
  RecurringConfig({
    this.enabled = false,
    this.frequency = RecurrenceFrequency.monthly,
    this.reminder = ReminderTiming.oneDayBefore,
    DateTime? startDate,
    this.endDate,
  }) : startDate = startDate ?? DateTime.now();

  bool enabled;
  RecurrenceFrequency frequency;
  ReminderTiming reminder;
  DateTime startDate;
  DateTime? endDate;

  RecurringConfig copyWith({
    bool? enabled,
    RecurrenceFrequency? frequency,
    ReminderTiming? reminder,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return RecurringConfig(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      reminder: reminder ?? this.reminder,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}

/// Lightweight stand-in for "recent merchant" suggestions. Designed to be
/// swapped out for a real provider/repository once smart suggestions land.
class RecentSuggestion {
  const RecentSuggestion({
    required this.merchant,
    required this.category,
    this.accountId,
    this.amount,
    this.recurring,
    this.kind = TransactionKind.expense,
  });

  final String merchant;
  final String category;
  final int? accountId;
  final double? amount;
  final RecurringConfig? recurring;
  final TransactionKind kind;
}

/// Mutable in-memory draft for the Add Transaction screen.
///
/// The screen owns one of these and mutates it directly through callbacks.
/// On save the page maps the draft into [Transaction] for persistence.
class TransactionDraft {
  TransactionDraft({
    this.editingId,
    this.kind = TransactionKind.expense,
    this.amount,
    this.currencyCode,
    this.categoryName,
    this.accountId,
    this.transferToAccountId,
    this.merchant = '',
    DateTime? date,
    this.note = '',
    RecurringConfig? recurring,
  })  : date = date ?? DateTime.now(),
        recurring = recurring ?? RecurringConfig();

  /// When set, save updates an existing row instead of inserting.
  int? editingId;
  TransactionKind kind;
  double? amount;
  String? currencyCode;
  String? categoryName;
  int? accountId;
  int? transferToAccountId;

  String merchant;
  DateTime date;
  String note;
  RecurringConfig recurring;

  bool get isRecurring => recurring.enabled;
  bool get isExpense => kind == TransactionKind.expense;
  bool get isIncome => kind == TransactionKind.income;
  bool get isTransfer => kind == TransactionKind.transfer;
  bool get isEditing => editingId != null;
}
