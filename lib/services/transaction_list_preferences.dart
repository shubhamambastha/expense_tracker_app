import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_filters.dart';

/// Local cache for transactions screen context (search history, filters, sort).
class TransactionListPreferences {
  TransactionListPreferences._();

  static final TransactionListPreferences instance =
      TransactionListPreferences._();

  static const _kRecentSearches = 'tx_list.recent_searches';
  static const _kLastSearch = 'tx_list.last_search';
  static const _kSort = 'tx_list.sort';
  static const _kDatePreset = 'tx_list.date_preset';
  static const _kCategory = 'tx_list.category';
  static const _kAccountId = 'tx_list.account_id';

  static const _maxRecent = 8;

  List<String> _recentSearches = [];
  bool _loaded = false;

  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kRecentSearches);
    _recentSearches = raw ?? [];
    _loaded = true;
  }

  Future<void> rememberSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await load();
    _recentSearches.removeWhere(
      (s) => s.toLowerCase() == trimmed.toLowerCase(),
    );
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > _maxRecent) {
      _recentSearches = _recentSearches.take(_maxRecent).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kRecentSearches, _recentSearches);
    await prefs.setString(_kLastSearch, trimmed);
  }

  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentSearches);
  }

  Future<String?> lastSearch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastSearch);
  }

  Future<void> saveFilterSnapshot(TransactionFilterState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSort, state.sort.name);
    if (state.datePreset != null) {
      await prefs.setString(_kDatePreset, state.datePreset!.name);
    } else {
      await prefs.remove(_kDatePreset);
    }
    if (state.category != null) {
      await prefs.setString(_kCategory, state.category!);
    } else {
      await prefs.remove(_kCategory);
    }
    if (state.accountId != null) {
      await prefs.setInt(_kAccountId, state.accountId!);
    } else {
      await prefs.remove(_kAccountId);
    }
  }

  Future<void> restoreFilterSnapshot(TransactionFilterState state) async {
    final prefs = await SharedPreferences.getInstance();
    final sortRaw = prefs.getString(_kSort);
    if (sortRaw != null) {
      for (final s in TransactionSort.values) {
        if (s.name == sortRaw) {
          state.sort = s;
          break;
        }
      }
    }
    final presetRaw = prefs.getString(_kDatePreset);
    if (presetRaw != null) {
      for (final p in DateFilterPreset.values) {
        if (p.name == presetRaw) {
          state.datePreset = p;
          break;
        }
      }
    }
    state.category = prefs.getString(_kCategory);
    state.accountId = prefs.getInt(_kAccountId);

    final last = prefs.getString(_kLastSearch);
    if (last != null && last.isNotEmpty) {
      state.searchQuery = last;
    }
  }

  /// Debug helper — not used in UI.
  String snapshotJson(TransactionFilterState state) =>
      jsonEncode({'sort': state.sort.name});
}
