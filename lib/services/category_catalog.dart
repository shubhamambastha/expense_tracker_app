import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../utils/category_style.dart';
import 'category_sync_cache.dart';
import 'supabase_service.dart';

/// Per-user expense categories synced with Supabase.
class CategoryCatalog extends ChangeNotifier {
  CategoryCatalog._() {
    _cache = CategorySyncCache<ExpenseCategory>(
      seeds: DefaultCategories.seeds,
      buildSeed:
          ({
            required name,
            required iconKey,
            required sortOrder,
            required isDefault,
          }) => ExpenseCategory(
            name: name,
            iconKey: iconKey,
            sortOrder: sortOrder,
            isDefault: isDefault,
          ),
      idOf: (c) => c.id,
      nameOf: (c) => c.name,
      isDefaultOf: (c) => c.isDefault,
      ensureDefaultsRemote: SupabaseService.ensureDefaultCategories,
      fetchRemote: SupabaseService.fetchCategories,
      insertRemote: SupabaseService.insertCategory,
      deleteRemote: SupabaseService.deleteCategory,
      onChanged: notifyListeners,
      debugLabel: 'CategoryCatalog',
    );
  }

  static final CategoryCatalog instance = CategoryCatalog._();

  late final CategorySyncCache<ExpenseCategory> _cache;

  List<ExpenseCategory> get categories => _cache.categories;

  List<String> get names => _cache.names;

  bool get isEmpty => _cache.isEmpty;

  ExpenseCategory? findByName(String name) => _cache.findByName(name);

  IconData iconForName(String name) =>
      CategoryIcons.iconForKey(findByName(name)?.iconKey);

  Color colorForName(String name) => colorForCategoryName(name, names);

  Future<void> syncForUser(String userId) => _cache.syncForUser(userId);

  void onSignedOut() => _cache.onSignedOut();

  Future<ExpenseCategory> addCategory({
    required String name,
    required String iconKey,
  }) => _cache.addCategory(name: name, iconKey: iconKey);

  Future<void> deleteCategory(ExpenseCategory category) =>
      _cache.deleteCategory(category);
}
