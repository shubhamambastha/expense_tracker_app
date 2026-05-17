import 'expense.dart';

class Account {
  final int? id;
  final String? userId;
  final String name;
  final AccountType type;

  const Account({this.id, this.userId, required this.name, required this.type});

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'type': type.name,
    };
  }
}
