import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../utils/category_style.dart';
import 'supabase_service.dart';

/// Per-user expense categories synced with Supabase.
class CategoryCatalog extends ChangeNotifier {
  CategoryCatalog._();

  static final CategoryCatalog instance = CategoryCatalog._();

  final List<ExpenseCategory> _categories = [];
  Future<void>? _syncInFlight;

  List<ExpenseCategory> get categories {
    _ensureDefaults();
    return List.unmodifiable(_categories);
  }

  List<String> get names {
    _ensureDefaults();
    return _categories.map((c) => c.name).toList();
  }

  void _ensureDefaults() {
    if (_categories.isEmpty) _loadLocalDefaults();
  }

  bool get isEmpty => _categories.isEmpty;

  ExpenseCategory? findByName(String name) {
    for (final c in _categories) {
      if (c.name == name) return c;
    }
    return null;
  }

  IconData iconForName(String name) =>
      CategoryIcons.iconForKey(findByName(name)?.iconKey);

  Color colorForName(String name) =>
      colorForCategoryName(name, names);

  Future<void> syncForUser(String userId) async {
    if (_syncInFlight != null) {
      await _syncInFlight;
      return;
    }

    _syncInFlight = _syncForUser(userId);
    try {
      await _syncInFlight;
    } finally {
      _syncInFlight = null;
    }
  }

  Future<void> _syncForUser(String userId) async {
    try {
      final remote = await SupabaseService.ensureDefaultCategories();
      _categories
        ..clear()
        ..addAll(remote);
      notifyListeners();
    } catch (error) {
      debugPrint('CategoryCatalog.syncForUser failed: $error');
      try {
        final remote = await SupabaseService.fetchCategories();
        if (remote.isNotEmpty) {
          _categories
            ..clear()
            ..addAll(remote);
          notifyListeners();
          return;
        }
      } catch (_) {
        // Fall through to local defaults.
      }
      if (_categories.isEmpty) {
        _loadLocalDefaults();
        notifyListeners();
      }
    }
  }

  void onSignedOut() {
    _categories.clear();
    _loadLocalDefaults();
    notifyListeners();
  }

  void _loadLocalDefaults() {
    _categories
      ..clear()
      ..addAll(
        DefaultCategories.seeds.asMap().entries.map(
          (e) => ExpenseCategory(
            name: e.value.name,
            iconKey: e.value.iconKey,
            sortOrder: e.key,
            isDefault: true,
          ),
        ),
      );
  }

  Future<ExpenseCategory> addCategory({
    required String name,
    required String iconKey,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Enter a category name');
    }
    if (_categories.any((c) => c.name.toLowerCase() == trimmed.toLowerCase())) {
      throw Exception('Category already exists');
    }

    final saved = await SupabaseService.insertCategory(
      name: trimmed,
      iconKey: iconKey,
      sortOrder: _categories.length,
    );
    _categories.add(saved);
    notifyListeners();
    return saved;
  }

  Future<void> deleteCategory(ExpenseCategory category) async {
    if (category.isDefault) {
      throw Exception('Default categories cannot be deleted');
    }
    if (category.id == null) return;

    await SupabaseService.deleteCategory(category.id!);
    _categories.removeWhere((c) => c.id == category.id);
    notifyListeners();
  }
}
