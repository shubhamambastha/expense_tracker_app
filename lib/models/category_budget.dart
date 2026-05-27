/// Per-user monthly budget for a single expense category.
class CategoryBudget {
  const CategoryBudget({
    this.id,
    this.userId,
    required this.categoryName,
    required this.monthlyLimit,
    this.currencyCode = 'INR',
    this.createdAt,
  });

  final int? id;
  final String? userId;
  final String categoryName;
  final double monthlyLimit;
  final String currencyCode;
  final DateTime? createdAt;

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    }

    return CategoryBudget(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['user_id'] as String?,
      categoryName: map['category_name'] as String? ?? '',
      monthlyLimit: (map['monthly_limit'] as num?)?.toDouble() ?? 0,
      currencyCode: map['currency_code'] as String? ?? 'INR',
      createdAt: parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'category_name': categoryName,
      'monthly_limit': monthlyLimit,
      'currency_code': currencyCode,
    };
  }

  CategoryBudget copyWith({
    int? id,
    String? userId,
    String? categoryName,
    double? monthlyLimit,
    String? currencyCode,
    DateTime? createdAt,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryName: categoryName ?? this.categoryName,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
