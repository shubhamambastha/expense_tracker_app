import 'expense.dart';

/// Known wallet / UPI providers stored in [walletProvider] when [type] is
/// [AccountType.other].
enum WalletProvider {
  gpay,
  phonepe,
  paytm,
  amazonPay,
  upi,
  other;

  String get label {
    switch (this) {
      case WalletProvider.gpay:
        return 'GPay';
      case WalletProvider.phonepe:
        return 'PhonePe';
      case WalletProvider.paytm:
        return 'Paytm';
      case WalletProvider.amazonPay:
        return 'Amazon Pay';
      case WalletProvider.upi:
        return 'UPI';
      case WalletProvider.other:
        return 'Other';
    }
  }

  static WalletProvider? fromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return WalletProvider.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => WalletProvider.other,
    );
  }
}

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

  /// Optional friendly label shown in lists.
  final String? nickname;

  /// Bank, issuer, or wallet app name (e.g. HDFC, GPay).
  final String? providerName;

  /// Free-form notes.
  final String? notes;

  /// Soft-hide without breaking transaction FKs.
  final bool isArchived;

  /// Credit card paying bank or wallet funding source.
  final int? linkedAccountId;

  /// When [type] is [AccountType.other], identifies the wallet/UPI app.
  final WalletProvider? walletProvider;

  const Account({
    this.id,
    this.userId,
    required this.name,
    required this.type,
    this.openingBalance = 0,
    this.creditLimit,
    this.statementDay,
    this.dueDay,
    this.nickname,
    this.providerName,
    this.notes,
    this.isArchived = false,
    this.linkedAccountId,
    this.walletProvider,
  });

  bool get isCreditCard => type == AccountType.creditCard;

  bool get isWallet =>
      type == AccountType.other && walletProvider != null;

  String get displayName =>
      (nickname != null && nickname!.trim().isNotEmpty)
          ? nickname!.trim()
          : name;

  String? get providerLabel {
    if (providerName != null && providerName!.trim().isNotEmpty) {
      return providerName!.trim();
    }
    if (walletProvider != null) return walletProvider!.label;
    return null;
  }

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
      nickname: map['nickname'] as String?,
      providerName: map['provider_name'] as String?,
      notes: map['notes'] as String?,
      isArchived: map['is_archived'] as bool? ?? false,
      linkedAccountId: _readLinkedId(map['linked_account_id']),
      walletProvider: WalletProvider.fromString(
        map['wallet_provider'] as String?,
      ),
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
      'nickname': nickname,
      'provider_name': providerName,
      'notes': notes,
      'is_archived': isArchived,
      'linked_account_id': linkedAccountId,
      'wallet_provider': walletProvider?.name,
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
    String? nickname,
    String? providerName,
    String? notes,
    bool? isArchived,
    int? linkedAccountId,
    WalletProvider? walletProvider,
    bool clearNickname = false,
    bool clearProviderName = false,
    bool clearNotes = false,
    bool clearCreditLimit = false,
    bool clearStatementDay = false,
    bool clearDueDay = false,
    bool clearLinkedAccountId = false,
    bool clearWalletProvider = false,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      creditLimit: clearCreditLimit ? null : (creditLimit ?? this.creditLimit),
      statementDay:
          clearStatementDay ? null : (statementDay ?? this.statementDay),
      dueDay: clearDueDay ? null : (dueDay ?? this.dueDay),
      nickname: clearNickname ? null : (nickname ?? this.nickname),
      providerName:
          clearProviderName ? null : (providerName ?? this.providerName),
      notes: clearNotes ? null : (notes ?? this.notes),
      isArchived: isArchived ?? this.isArchived,
      linkedAccountId: clearLinkedAccountId
          ? null
          : (linkedAccountId ?? this.linkedAccountId),
      walletProvider: clearWalletProvider
          ? null
          : (walletProvider ?? this.walletProvider),
    );
  }

  static int? _readDay(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  static int? _readLinkedId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }
}
