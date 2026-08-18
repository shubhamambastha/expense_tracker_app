import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_filters.dart';

/// Local cache for transactions screen context (filters, sort).
class TransactionListPreferences {
  TransactionListPreferences._();

  static final TransactionListPreferences instance =
      TransactionListPreferences._();

  static const _kSort = 'tx_list.sort';
  static const _kDatePreset = 'tx_list.date_preset';
  static const _kCategory = 'tx_list.category';
  static const _kAccountId = 'tx_list.account_id';

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
  }
}
