import 'expense.dart';

class Account {
  final int? id;
  final String? userId;
  final String name;
  final AccountType type;

  /// Manual balance baseline. Combined with transactions to compute the
  /// current balance. For credit cards this is typically `0` (no opening
  /// balance) and the running balance becomes negative as charges accrue.
  final double openingBalance;

  /// Credit limit on a credit card. Null for non-credit accounts.
  final double? creditLimit;

  /// Day of month the statement closes (1-31). Null when unknown.
  final int? statementDay;

  /// Day of month the bill is due (1-31). Null when unknown.
  final int? dueDay;

  const Account({
    this.id,
    this.userId,
    required this.name,
    required this.type,
    this.openingBalance = 0,
    this.creditLimit,
    this.statementDay,
    this.dueDay,
  });

  bool get isCreditCard => type == AccountType.creditCard;

  factory Account.fromMap(Map<String, dynamic> map) {
    final typeString = map['type'] as String? ?? 'bank';
    return Account(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['user_id'] as String?,
      name: map['name'] as String? ?? '',
      type: AccountType.values.firstWhere(
        (value) => value.name == typeString,
        orElse: () => AccountType.bank,
      ),
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0,
      creditLimit: (map['credit_limit'] as num?)?.toDouble(),
      statementDay: _readDay(map['statement_day']),
      dueDay: _readDay(map['due_day']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'type': type.name,
      'opening_balance': openingBalance,
      'credit_limit': creditLimit,
      'statement_day': statementDay,
      'due_day': dueDay,
    };
  }

  Account copyWith({
    int? id,
    String? userId,
    String? name,
    AccountType? type,
    double? openingBalance,
    double? creditLimit,
    int? statementDay,
    int? dueDay,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
    );
  }

  static int? _readDay(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }
}
