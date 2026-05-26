import 'account.dart';
import 'transaction_draft.dart';

/// Unified money event persisted in `public.transactions`.
class Transaction {
  const Transaction({
    this.id,
    this.userId,
    this.kind = TransactionKind.expense,
    required this.amount,
    this.currencyCode = 'INR',
    this.category,
    required this.counterpartyName,
    this.note,
    this.accountId,
    this.transferToAccountId,
    required this.date,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurrenceStartDate,
    this.recurrenceEndDate,
    this.reminderTiming,
    this.insertedAt,
  });

  final int? id;
  final String? userId;
  final TransactionKind kind;
  final double amount;
  final String currencyCode;
  final String? category;
  final String counterpartyName;
  final String? note;
  final int? accountId;
  final int? transferToAccountId;
  final DateTime date;
  final bool isRecurring;
  final RecurrenceFrequency? recurrenceFrequency;
  final DateTime? recurrenceStartDate;
  final DateTime? recurrenceEndDate;
  final ReminderTiming? reminderTiming;
  final DateTime? insertedAt;

  /// Alias used by legacy expense-oriented UI.
  String get name => counterpartyName;

  bool get isExpense => kind == TransactionKind.expense;
  bool get isIncome => kind == TransactionKind.income;
  bool get isTransfer => kind == TransactionKind.transfer;

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final kindRaw = map['kind'] as String? ?? 'expense';
    final kind = TransactionKind.values.firstWhere(
      (k) => k.name == kindRaw,
      orElse: () => TransactionKind.expense,
    );

    RecurrenceFrequency? frequency;
    final freqRaw = map['recurrence_frequency'] as String?;
    if (freqRaw != null) {
      frequency = RecurrenceFrequency.values.firstWhere(
        (f) => f.name == freqRaw,
        orElse: () => RecurrenceFrequency.monthly,
      );
    }

    ReminderTiming? reminder;
    final reminderRaw = map['reminder_timing'] as String?;
    if (reminderRaw != null) {
      reminder = ReminderTiming.values.firstWhere(
        (r) => r.name == reminderRaw,
        orElse: () => ReminderTiming.oneDayBefore,
      );
    }

    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      return DateTime.parse(raw as String);
    }

    return Transaction(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['user_id'] as String?,
      kind: kind,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currencyCode: map['currency_code'] as String? ?? 'INR',
      category: map['category'] as String?,
      counterpartyName: (map['counterparty_name'] as String?) ??
          (map['name'] as String?) ??
          '',
      note: map['note'] as String?,
      accountId: map['account_id'] is int
          ? map['account_id'] as int
          : int.tryParse(map['account_id']?.toString() ?? ''),
      transferToAccountId: map['transfer_to_account_id'] is int
          ? map['transfer_to_account_id'] as int
          : int.tryParse(map['transfer_to_account_id']?.toString() ?? ''),
      date: DateTime.parse(map['date'] as String),
      isRecurring: map['is_recurring'] as bool? ?? false,
      recurrenceFrequency: frequency,
      recurrenceStartDate: parseDate(map['recurrence_start_date']),
      recurrenceEndDate: parseDate(map['recurrence_end_date']),
      reminderTiming: reminder,
      insertedAt: parseDate(map['inserted_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'kind': kind.name,
      'amount': amount,
      'currency_code': currencyCode,
      'category': category,
      'counterparty_name': counterpartyName,
      if (note != null && note!.isNotEmpty) 'note': note,
      'account_id': accountId,
      if (transferToAccountId != null)
        'transfer_to_account_id': transferToAccountId,
      'date': date.toIso8601String(),
      'is_recurring': isRecurring,
      if (isRecurring && recurrenceFrequency != null)
        'recurrence_frequency': recurrenceFrequency!.name,
      if (isRecurring && recurrenceStartDate != null)
        'recurrence_start_date': recurrenceStartDate!.toIso8601String(),
      if (isRecurring && recurrenceEndDate != null)
        'recurrence_end_date': recurrenceEndDate!.toIso8601String(),
      if (isRecurring && reminderTiming != null)
        'reminder_timing': reminderTiming!.name,
    };
  }

  Transaction copyWith({
    int? id,
    String? userId,
    TransactionKind? kind,
    double? amount,
    String? currencyCode,
    String? category,
    String? counterpartyName,
    String? note,
    int? accountId,
    int? transferToAccountId,
    DateTime? date,
    bool? isRecurring,
    RecurrenceFrequency? recurrenceFrequency,
    DateTime? recurrenceStartDate,
    DateTime? recurrenceEndDate,
    ReminderTiming? reminderTiming,
    DateTime? insertedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      category: category ?? this.category,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      note: note ?? this.note,
      accountId: accountId ?? this.accountId,
      transferToAccountId: transferToAccountId ?? this.transferToAccountId,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceStartDate: recurrenceStartDate ?? this.recurrenceStartDate,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      reminderTiming: reminderTiming ?? this.reminderTiming,
      insertedAt: insertedAt ?? this.insertedAt,
    );
  }

  TransactionDraft toDraft() {
    return TransactionDraft(
      editingId: id,
      kind: kind,
      amount: amount,
      currencyCode: currencyCode,
      categoryName: category,
      accountId: accountId,
      transferToAccountId: transferToAccountId,
      merchant: counterpartyName,
      date: date,
      note: note ?? '',
      recurring: RecurringConfig(
        enabled: isRecurring,
        frequency: recurrenceFrequency ?? RecurrenceFrequency.monthly,
        reminder: reminderTiming ?? ReminderTiming.oneDayBefore,
        startDate: recurrenceStartDate ?? date,
        endDate: recurrenceEndDate,
      ),
    );
  }
}

extension TransactionDraftPersistence on TransactionDraft {
  Transaction toTransaction({
    required Account account,
    Account? transferToAccount,
  }) {
    final toId = transferToAccount?.id ?? transferToAccountId;
    final label = merchant.trim().isEmpty
        ? (categoryName ?? _defaultLabelForKind(kind))
        : merchant.trim();

    return Transaction(
      id: editingId,
      kind: kind,
      amount: amount ?? 0,
      currencyCode: currencyCode ?? 'INR',
      category: categoryName,
      counterpartyName: label,
      note: note.isEmpty ? null : note,
      accountId: account.id,
      transferToAccountId: kind == TransactionKind.transfer ? toId : null,
      date: date,
      isRecurring: recurring.enabled,
      recurrenceFrequency:
          recurring.enabled ? recurring.frequency : null,
      recurrenceStartDate: recurring.enabled ? recurring.startDate : null,
      recurrenceEndDate: recurring.enabled ? recurring.endDate : null,
      reminderTiming: recurring.enabled ? recurring.reminder : null,
    );
  }

  static String _defaultLabelForKind(TransactionKind kind) {
    switch (kind) {
      case TransactionKind.expense:
        return 'Untitled';
      case TransactionKind.income:
        return 'Income';
      case TransactionKind.transfer:
        return 'Transfer';
    }
  }
}
