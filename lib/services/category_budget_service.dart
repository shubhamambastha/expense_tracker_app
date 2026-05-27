import 'package:flutter/foundation.dart';

import '../models/category_budget.dart';
import 'supabase_service.dart';

/// In-memory cache of the signed-in user's category budgets, kept in sync
/// with `public.category_budgets`. Mirrors [CategoryCatalog]'s shape so the
/// dashboard can listen via [ListenableBuilder] without an extra package.
class CategoryBudgetService extends ChangeNotifier {
  CategoryBudgetService._();

  static final CategoryBudgetService instance = CategoryBudgetService._();

  final List<CategoryBudget> _budgets = [];
  Future<void>? _syncInFlight;

  List<CategoryBudget> get budgets => List.unmodifiable(_budgets);

  bool get isEmpty => _budgets.isEmpty;

  CategoryBudget? findByCategory(String name) {
    final key = name.trim().toLowerCase();
    for (final b in _budgets) {
      if (b.categoryName.toLowerCase() == key) return b;
    }
    return null;
  }

  Future<void> refresh() async {
    if (_syncInFlight != null) {
      await _syncInFlight;
      return;
    }
    _syncInFlight = _refresh();
    try {
      await _syncInFlight;
    } finally {
      _syncInFlight = null;
    }
  }

  Future<void> _refresh() async {
    try {
      final remote = await SupabaseService.fetchCategoryBudgets();
      _budgets
        ..clear()
        ..addAll(remote);
      notifyListeners();
    } catch (error) {
      debugPrint('CategoryBudgetService.refresh failed: $error');
    }
  }

  /// Upserts a budget; the unique index ensures only one row per category.
  Future<CategoryBudget> upsert({
    required String categoryName,
    required double monthlyLimit,
    String currencyCode = 'INR',
  }) async {
    final trimmed = categoryName.trim();
    if (trimmed.isEmpty) {
      throw Exception('Pick a category to budget');
    }
    if (monthlyLimit <= 0) {
      throw Exception('Enter a positive amount');
    }

    final existing = findByCategory(trimmed);
    final draft = CategoryBudget(
      id: existing?.id,
      categoryName: trimmed,
      monthlyLimit: monthlyLimit,
      currencyCode: currencyCode,
    );

    final saved = await SupabaseService.upsertCategoryBudget(draft);
    final idx = _budgets.indexWhere(
      (b) => b.categoryName.toLowerCase() == saved.categoryName.toLowerCase(),
    );
    if (idx >= 0) {
      _budgets[idx] = saved;
    } else {
      _budgets.add(saved);
    }
    _budgets.sort(
      (a, b) => a.categoryName.toLowerCase().compareTo(
            b.categoryName.toLowerCase(),
          ),
    );
    notifyListeners();
    return saved;
  }

  Future<void> remove(CategoryBudget budget) async {
    if (budget.id == null) return;
    await SupabaseService.deleteCategoryBudget(budget.id!);
    _budgets.removeWhere((b) => b.id == budget.id);
    notifyListeners();
  }

  void onSignedOut() {
    _budgets.clear();
    notifyListeners();
  }
}
