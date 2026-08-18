import 'package:flutter/material.dart';

import '../models/income_category.dart';
import '../utils/category_style.dart';
import 'category_sync_cache.dart';
import 'supabase_service.dart';

/// Per-user income categories synced with Supabase.
class IncomeCategoryCatalog extends ChangeNotifier {
  IncomeCategoryCatalog._() {
    _cache = CategorySyncCache<IncomeCategory>(
      seeds: DefaultIncomeCategories.seeds,
      buildSeed:
          ({
            required name,
            required iconKey,
            required sortOrder,
            required isDefault,
          }) => IncomeCategory(
            name: name,
            iconKey: iconKey,
            sortOrder: sortOrder,
            isDefault: isDefault,
          ),
      idOf: (c) => c.id,
      nameOf: (c) => c.name,
      isDefaultOf: (c) => c.isDefault,
      ensureDefaultsRemote: SupabaseService.ensureDefaultIncomeCategories,
      fetchRemote: SupabaseService.fetchIncomeCategories,
      insertRemote: SupabaseService.insertIncomeCategory,
      deleteRemote: SupabaseService.deleteIncomeCategory,
      onChanged: notifyListeners,
      debugLabel: 'IncomeCategoryCatalog',
    );
  }

  static final IncomeCategoryCatalog instance = IncomeCategoryCatalog._();

  late final CategorySyncCache<IncomeCategory> _cache;

  List<IncomeCategory> get categories => _cache.categories;

  List<String> get names => _cache.names;

  bool get isEmpty => _cache.isEmpty;

  IncomeCategory? findByName(String name) => _cache.findByName(name);

  IconData iconForName(String name) =>
      CategoryIcons.iconForKey(findByName(name)?.iconKey);

  Color colorForName(String name) => colorForCategoryName(name, names);

  Future<void> syncForUser(String userId) => _cache.syncForUser(userId);

  void onSignedOut() => _cache.onSignedOut();

  Future<IncomeCategory> addCategory({
    required String name,
    required String iconKey,
  }) => _cache.addCategory(name: name, iconKey: iconKey);

  Future<void> deleteCategory(IncomeCategory category) =>
      _cache.deleteCategory(category);
}
