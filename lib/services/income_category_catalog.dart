import 'package:flutter/material.dart';

import '../models/income_category.dart';
import '../utils/category_style.dart';
import 'supabase_service.dart';

/// Per-user income categories synced with Supabase.
class IncomeCategoryCatalog extends ChangeNotifier {
  IncomeCategoryCatalog._();

  static final IncomeCategoryCatalog instance = IncomeCategoryCatalog._();

  final List<IncomeCategory> _categories = [];
  Future<void>? _syncInFlight;

  List<IncomeCategory> get categories {
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

  IncomeCategory? findByName(String name) {
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
      final remote = await SupabaseService.ensureDefaultIncomeCategories();
      _categories
        ..clear()
        ..addAll(remote);
      notifyListeners();
    } catch (error) {
      debugPrint('IncomeCategoryCatalog.syncForUser failed: $error');
      try {
        final remote = await SupabaseService.fetchIncomeCategories();
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
        DefaultIncomeCategories.seeds.asMap().entries.map(
          (e) => IncomeCategory(
            name: e.value.name,
            iconKey: e.value.iconKey,
            sortOrder: e.key,
            isDefault: true,
          ),
        ),
      );
  }

  Future<IncomeCategory> addCategory({
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

    final saved = await SupabaseService.insertIncomeCategory(
      name: trimmed,
      iconKey: iconKey,
      sortOrder: _categories.length,
    );
    _categories.add(saved);
    notifyListeners();
    return saved;
  }

  Future<void> deleteCategory(IncomeCategory category) async {
    if (category.isDefault) {
      throw Exception('Default categories cannot be deleted');
    }
    if (category.id == null) return;

    await SupabaseService.deleteIncomeCategory(category.id!);
    _categories.removeWhere((c) => c.id == category.id);
    notifyListeners();
  }
}
