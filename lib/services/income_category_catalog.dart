import 'package:flutter/material.dart';

import '../models/income_category.dart';
import '../utils/category_style.dart';

/// Static income categories for the Add Transaction income mode.
///
/// Kept separate from [CategoryCatalog] (expense categories) so income and
/// expense flows never share the wrong pill list. Ready to sync from Supabase
/// later without changing section widgets.
class IncomeCategoryCatalog {
  IncomeCategoryCatalog._();

  static final IncomeCategoryCatalog instance = IncomeCategoryCatalog._();

  static const List<IncomeCategory> categories = [
    IncomeCategory(name: 'Salary', iconKey: 'work_rounded'),
    IncomeCategory(name: 'Freelance', iconKey: 'work_rounded'),
    IncomeCategory(name: 'Refund', iconKey: 'receipt_rounded'),
    IncomeCategory(name: 'Bonus', iconKey: 'savings_rounded'),
    IncomeCategory(name: 'Gift', iconKey: 'card_giftcard_rounded'),
    IncomeCategory(name: 'Cashback', iconKey: 'savings_rounded'),
    IncomeCategory(name: 'Investment', iconKey: 'savings_rounded'),
    IncomeCategory(name: 'Rental', iconKey: 'home_rounded'),
  ];

  List<String> get names => categories.map((c) => c.name).toList();

  IncomeCategory? findByName(String name) {
    for (final c in categories) {
      if (c.name == name) return c;
    }
    return null;
  }

  IconData iconForName(String name) =>
      CategoryIcons.iconForKey(findByName(name)?.iconKey);

  Color colorForName(String name) =>
      colorForCategoryName(name, names);
}
