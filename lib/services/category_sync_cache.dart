import 'package:flutter/foundation.dart';

/// Shared list<->Supabase sync/cache logic for per-user category catalogs.
///
/// [CategoryCatalog] (expense) and [IncomeCategoryCatalog] (income) have
/// identical shape — remote-first load with local-default fallback, optimistic
/// add/delete, single-flight sync — so this holds the one copy of that logic.
/// Each catalog only supplies its model type via the callbacks below and
/// forwards [onChanged] to its own `notifyListeners`.
class CategorySyncCache<T> {
  CategorySyncCache({
    required this.seeds,
    required this.buildSeed,
    required this.idOf,
    required this.nameOf,
    required this.isDefaultOf,
    required this.ensureDefaultsRemote,
    required this.fetchRemote,
    required this.insertRemote,
    required this.deleteRemote,
    required this.onChanged,
    required this.debugLabel,
  });

  final List<({String name, String iconKey})> seeds;
  final T Function({
    required String name,
    required String iconKey,
    required int sortOrder,
    required bool isDefault,
  })
  buildSeed;
  final int? Function(T category) idOf;
  final String Function(T category) nameOf;
  final bool Function(T category) isDefaultOf;
  final Future<List<T>> Function() ensureDefaultsRemote;
  final Future<List<T>> Function() fetchRemote;
  final Future<T> Function({
    required String name,
    required String iconKey,
    required int sortOrder,
  })
  insertRemote;
  final Future<void> Function(int id) deleteRemote;
  final VoidCallback onChanged;
  final String debugLabel;

  final List<T> _categories = [];
  Future<void>? _syncInFlight;

  List<T> get categories {
    _ensureDefaults();
    return List.unmodifiable(_categories);
  }

  List<String> get names {
    _ensureDefaults();
    return _categories.map(nameOf).toList();
  }

  void _ensureDefaults() {
    if (_categories.isEmpty) _loadLocalDefaults();
  }

  bool get isEmpty => _categories.isEmpty;

  T? findByName(String name) {
    for (final c in _categories) {
      if (nameOf(c) == name) return c;
    }
    return null;
  }

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
      final remote = await ensureDefaultsRemote();
      _categories
        ..clear()
        ..addAll(remote);
      onChanged();
    } catch (error) {
      debugPrint('$debugLabel.syncForUser failed: $error');
      try {
        final remote = await fetchRemote();
        if (remote.isNotEmpty) {
          _categories
            ..clear()
            ..addAll(remote);
          onChanged();
          return;
        }
      } catch (_) {
        // Fall through to local defaults.
      }
      if (_categories.isEmpty) {
        _loadLocalDefaults();
        onChanged();
      }
    }
  }

  void onSignedOut() {
    _categories.clear();
    _loadLocalDefaults();
    onChanged();
  }

  void _loadLocalDefaults() {
    _categories
      ..clear()
      ..addAll(
        seeds.asMap().entries.map(
          (e) => buildSeed(
            name: e.value.name,
            iconKey: e.value.iconKey,
            sortOrder: e.key,
            isDefault: true,
          ),
        ),
      );
  }

  Future<T> addCategory({required String name, required String iconKey}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Enter a category name');
    }
    if (_categories.any(
      (c) => nameOf(c).toLowerCase() == trimmed.toLowerCase(),
    )) {
      throw Exception('Category already exists');
    }

    final saved = await insertRemote(
      name: trimmed,
      iconKey: iconKey,
      sortOrder: _categories.length,
    );
    _categories.add(saved);
    onChanged();
    return saved;
  }

  Future<void> deleteCategory(T category) async {
    if (isDefaultOf(category)) {
      throw Exception('Default categories cannot be deleted');
    }
    final id = idOf(category);
    if (id == null) return;

    await deleteRemote(id);
    _categories.removeWhere((c) => idOf(c) == id);
    onChanged();
  }
}
