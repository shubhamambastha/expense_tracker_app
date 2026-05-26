enum ExpenseType { oneTime, recurring }

enum AccountType { bank, creditCard, cash, other }

class Expense {
  final int? id;
  final String? userId;
  final String name;
  final String category;
  final DateTime date;
  final ExpenseType type;
  final DateTime? endDate;
  final int? accountId;
  final double amount;

  Expense({
    this.id,
    this.userId,
    required this.name,
    required this.category,
    required this.date,
    required this.type,
    required this.amount,
    required this.accountId,
    this.endDate,
  });

  bool get isRecurring => type == ExpenseType.recurring;

  factory Expense.fromMap(Map<String, dynamic> map) {
    // The persistence layer is now the unified `transactions` table
    // (see sql/20260526_create_transactions.sql). The new schema uses
    // `counterparty_name`, `is_recurring`, and `recurrence_end_date`, but we
    // still accept the legacy `expenses` column names so older payloads
    // (e.g. from cached responses) keep parsing.
    final isRecurring = map['is_recurring'] as bool? ??
        ((map['type'] as String?) == 'recurring');
    final name = (map['counterparty_name'] as String?) ??
        (map['name'] as String?) ??
        '';
    final endDateRaw = map['recurrence_end_date'] ?? map['end_date'];
    return Expense(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['user_id'] as String?,
      name: name,
      category: map['category'] as String? ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date'] as String),
      type: isRecurring ? ExpenseType.recurring : ExpenseType.oneTime,
      accountId: map['account_id'] is int
          ? map['account_id'] as int
          : int.tryParse(map['account_id']?.toString() ?? ''),
      endDate: endDateRaw == null ? null : DateTime.parse(endDateRaw as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'kind': 'expense',
      'counterparty_name': name,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'is_recurring': isRecurring,
      'account_id': accountId,
      'recurrence_end_date': endDate?.toIso8601String(),
    };
  }
}

extension ExpenseTypeLabel on ExpenseType {
  String get label {
    switch (this) {
      case ExpenseType.oneTime:
        return 'One-time';
      case ExpenseType.recurring:
        return 'Recurring';
    }
  }
}

extension AccountTypeLabel on AccountType {
  String get label {
    switch (this) {
      case AccountType.bank:
        return 'Bank';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.cash:
        return 'Cash';
      case AccountType.other:
        return 'Other';
    }
  }
}
