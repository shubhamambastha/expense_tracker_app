class ExpenseCategory {
  const ExpenseCategory({
    this.id,
    this.userId,
    required this.name,
    required this.iconKey,
    this.sortOrder = 0,
    this.isDefault = false,
  });

  final int? id;
  final String? userId;
  final String name;
  final String iconKey;
  final int sortOrder;
  final bool isDefault;

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['user_id'] as String?,
      name: map['name'] as String? ?? '',
      iconKey: map['icon'] as String? ?? 'category_rounded',
      sortOrder: map['sort_order'] is int
          ? map['sort_order'] as int
          : int.tryParse(map['sort_order']?.toString() ?? '') ?? 0,
      isDefault: map['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'icon': iconKey,
      'sort_order': sortOrder,
      'is_default': isDefault,
    };
  }
}
