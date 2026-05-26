import '../models/account.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import '../models/transaction_filters.dart';
import '../utils/transaction_subtype_helpers.dart';

class TransactionFilterLogic {
  TransactionFilterLogic._();

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static (DateTime?, DateTime?) dateRangeForPreset(
    DateFilterPreset preset,
    DateTime now, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final today = _startOfDay(now);
    switch (preset) {
      case DateFilterPreset.today:
        return (today, _endOfDay(now));
      case DateFilterPreset.thisWeek:
        final start = today.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return (start, _endOfDay(end));
      case DateFilterPreset.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return (start, _endOfDay(end));
      case DateFilterPreset.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0);
        return (start, _endOfDay(end));
      case DateFilterPreset.custom:
        return (customStart, customEnd != null ? _endOfDay(customEnd) : null);
    }
  }

  static List<Transaction> apply({
    required List<Transaction> transactions,
    required TransactionFilterState filters,
    required List<Account> accounts,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final query = filters.searchQuery.toLowerCase().trim();

    DateTime? rangeStart;
    DateTime? rangeEnd;
    if (filters.datePreset != null) {
      final range = dateRangeForPreset(
        filters.datePreset!,
        clock,
        customStart: filters.customStart,
        customEnd: filters.customEnd,
      );
      rangeStart = range.$1;
      rangeEnd = range.$2;
    } else if (filters.customStart != null || filters.customEnd != null) {
      rangeStart = filters.customStart;
      rangeEnd =
          filters.customEnd != null ? _endOfDay(filters.customEnd!) : null;
    }

    final filtered = transactions.where((tx) {
      if (filters.category != null && tx.category != filters.category) {
        return false;
      }

      if (filters.accountId != null && tx.accountId != filters.accountId) {
        return false;
      }

      if (filters.types.isNotEmpty) {
        final displayType = displayTypeForTransaction(tx);
        if (!filters.types.contains(displayType)) return false;
      }

      if (rangeStart != null && tx.date.isBefore(rangeStart)) {
        return false;
      }
      if (rangeEnd != null && tx.date.isAfter(rangeEnd)) {
        return false;
      }

      if (filters.minAmount != null && tx.amount < filters.minAmount!) {
        return false;
      }
      if (filters.maxAmount != null && tx.amount > filters.maxAmount!) {
        return false;
      }

      if (query.isEmpty) return true;

      final account = _accountFor(tx, accounts);
      final toAccount = _accountForId(tx.transferToAccountId, accounts);
      final accountLabel = account?.name.toLowerCase() ?? '';
      final toLabel = toAccount?.name.toLowerCase() ?? '';
      final note = tx.note?.toLowerCase() ?? '';
      return tx.counterpartyName.toLowerCase().contains(query) ||
          (tx.category ?? '').toLowerCase().contains(query) ||
          accountLabel.contains(query) ||
          toLabel.contains(query) ||
          note.contains(query);
    }).toList();

    return sort(filtered, filters.sort);
  }

  static List<Transaction> sort(List<Transaction> items, TransactionSort sort) {
    final copy = List<Transaction>.from(items);
    switch (sort) {
      case TransactionSort.latestFirst:
        copy.sort((a, b) => b.date.compareTo(a.date));
      case TransactionSort.highestAmount:
        copy.sort((a, b) => b.amount.compareTo(a.amount));
      case TransactionSort.lowestAmount:
        copy.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return copy;
  }

  static Account? _accountFor(Transaction tx, List<Account> accounts) =>
      _accountForId(tx.accountId, accounts);

  static Account? _accountForId(int? id, List<Account> accounts) {
    if (id == null) return null;
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  /// Top expense category by spend in the filtered set.
  static String? topCategory(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.isExpense);
    if (expenses.isEmpty) return null;
    final totals = <String, double>{};
    for (final e in expenses) {
      final cat = e.category ?? 'Other';
      totals[cat] = (totals[cat] ?? 0) + e.amount;
    }
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static double totalSpent(List<Transaction> transactions) => transactions
      .where((t) => t.kind == TransactionKind.expense)
      .fold(0.0, (sum, e) => sum + e.amount);
}
