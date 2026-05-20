import 'package:flutter/material.dart';

/// Chart / list accent colors (aligned across the app).
const kCategoryColors = <Color>[
  Color(0xFF4F8EF7),
  Color(0xFF47B881),
  Color(0xFFF8B229),
  Color(0xFF8E5AF7),
  Color(0xFFF15C5C),
  Color(0xFF3FB0AC),
  Color(0xFFF88D42),
  Color(0xFF6B7A8F),
];

/// Material icon keys stored in Supabase (`icon` column).
class CategoryIcons {
  CategoryIcons._();

  static const String defaultKey = 'category_rounded';

  static const List<({String key, IconData icon, String label})> pickerOptions = [
    (key: 'restaurant_rounded', icon: Icons.restaurant_rounded, label: 'Food'),
    (key: 'shopping_bag_rounded', icon: Icons.shopping_bag_rounded, label: 'Shopping'),
    (key: 'flight_takeoff_rounded', icon: Icons.flight_takeoff_rounded, label: 'Travel'),
    (key: 'receipt_rounded', icon: Icons.receipt_rounded, label: 'Bills'),
    (key: 'favorite_rounded', icon: Icons.favorite_rounded, label: 'Health'),
    (key: 'movie_rounded', icon: Icons.movie_rounded, label: 'Fun'),
    (key: 'home_rounded', icon: Icons.home_rounded, label: 'Home'),
    (key: 'directions_car_rounded', icon: Icons.directions_car_rounded, label: 'Transport'),
    (key: 'school_rounded', icon: Icons.school_rounded, label: 'Education'),
    (key: 'work_rounded', icon: Icons.work_rounded, label: 'Work'),
    (key: 'pets_rounded', icon: Icons.pets_rounded, label: 'Pets'),
    (key: 'child_care_rounded', icon: Icons.child_care_rounded, label: 'Family'),
    (key: 'fitness_center_rounded', icon: Icons.fitness_center_rounded, label: 'Fitness'),
    (key: 'savings_rounded', icon: Icons.savings_rounded, label: 'Savings'),
    (key: 'card_giftcard_rounded', icon: Icons.card_giftcard_rounded, label: 'Gifts'),
    (key: 'local_cafe_rounded', icon: Icons.local_cafe_rounded, label: 'Cafe'),
    (key: 'checkroom_rounded', icon: Icons.checkroom_rounded, label: 'Clothes'),
    (key: 'phone_android_rounded', icon: Icons.phone_android_rounded, label: 'Tech'),
    (key: 'category_rounded', icon: Icons.category_rounded, label: 'Other'),
    (key: 'more_horiz_rounded', icon: Icons.more_horiz_rounded, label: 'Misc'),
  ];

  static final Map<String, IconData> _byKey = {
    for (final o in pickerOptions) o.key: o.icon,
  };

  static IconData iconForKey(String? key) =>
      _byKey[key] ?? Icons.category_rounded;

  static Color colorAtIndex(int index) =>
      kCategoryColors[index.abs() % kCategoryColors.length];
}

/// Built-in categories seeded for new users.
class DefaultCategories {
  DefaultCategories._();

  static const seeds = <({String name, String iconKey})>[
    (name: 'Food', iconKey: 'restaurant_rounded'),
    (name: 'Shopping', iconKey: 'shopping_bag_rounded'),
    (name: 'Travel', iconKey: 'flight_takeoff_rounded'),
    (name: 'Bills', iconKey: 'receipt_rounded'),
    (name: 'Health', iconKey: 'favorite_rounded'),
    (name: 'Entertainment', iconKey: 'movie_rounded'),
    (name: 'Other', iconKey: 'more_horiz_rounded'),
  ];
}

Color colorForCategoryName(String name, List<String> orderedNames) {
  final index = orderedNames.indexOf(name);
  if (index >= 0) return CategoryIcons.colorAtIndex(index);
  return CategoryIcons.colorAtIndex(name.hashCode);
}
