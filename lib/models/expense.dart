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
  final AccountType accountType;
  final double amount;

  Expense({
    this.id,
    this.userId,
    required this.name,
    required this.category,
    required this.date,
    required this.type,
    required this.accountType,
    required this.amount,
    this.endDate,
  });

  bool get isRecurring => type == ExpenseType.recurring;

  factory Expense.fromMap(Map<String, dynamic> map) {
    final typeString = map['type'] as String? ?? 'oneTime';
    final accountString = map['account_type'] as String? ?? 'bank';
    return Expense(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['user_id'] as String?,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date'] as String),
      type: ExpenseType.values.firstWhere(
        (value) => value.name == typeString,
        orElse: () => ExpenseType.oneTime,
      ),
      accountType: AccountType.values.firstWhere(
        (value) => value.name == accountString,
        orElse: () => AccountType.bank,
      ),
      endDate: map['end_date'] == null ? null : DateTime.parse(map['end_date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'account_type': accountType.name,
      'end_date': endDate?.toIso8601String(),
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
