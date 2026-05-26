import 'package:flutter/foundation.dart';

/// Display-oriented transaction kinds for filtering. Derived from persisted
/// `kind` + `category` — see [displayTypeForTransaction] in
/// `transaction_subtype_helpers.dart`.
enum TransactionDisplayType {
  expense,
  income,
  transfer,
  emi,
  subscription,
  refund,
}

extension TransactionDisplayTypeLabel on TransactionDisplayType {
  String get label {
    switch (this) {
      case TransactionDisplayType.expense:
        return 'Expense';
      case TransactionDisplayType.income:
        return 'Income';
      case TransactionDisplayType.transfer:
        return 'Transfer';
      case TransactionDisplayType.emi:
        return 'EMI';
      case TransactionDisplayType.subscription:
        return 'Subscription';
      case TransactionDisplayType.refund:
        return 'Refund';
    }
  }
}

/// Quick date presets for the filter row.
enum DateFilterPreset {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  custom,
}

extension DateFilterPresetLabel on DateFilterPreset {
  String get label {
    switch (this) {
      case DateFilterPreset.today:
        return 'Today';
      case DateFilterPreset.thisWeek:
        return 'This Week';
      case DateFilterPreset.thisMonth:
        return 'This Month';
      case DateFilterPreset.lastMonth:
        return 'Last Month';
      case DateFilterPreset.custom:
        return 'Custom Range';
    }
  }
}

enum TransactionSort {
  latestFirst,
  highestAmount,
  lowestAmount,
}

extension TransactionSortLabel on TransactionSort {
  String get label {
    switch (this) {
      case TransactionSort.latestFirst:
        return 'Latest First';
      case TransactionSort.highestAmount:
        return 'Highest Amount';
      case TransactionSort.lowestAmount:
        return 'Lowest Amount';
    }
  }
}

/// Removable chip shown below the filter row when filters are active.
@immutable
class ActiveFilterChip {
  const ActiveFilterChip({
    required this.id,
    required this.label,
    required this.onRemove,
  });

  final String id;
  final String label;
  final VoidCallback onRemove;
}

/// Mutable filter state owned by the transactions screen.
class TransactionFilterState {
  TransactionFilterState({
    this.searchQuery = '',
    this.datePreset,
    this.customStart,
    this.customEnd,
    this.types = const {},
    this.category,
    this.accountId,
    this.currencyCode,
    this.minAmount,
    this.maxAmount,
    this.tags = const {},
    this.sort = TransactionSort.latestFirst,
  });

  String searchQuery;
  DateFilterPreset? datePreset;
  DateTime? customStart;
  DateTime? customEnd;
  Set<TransactionDisplayType> types;
  String? category;
  int? accountId;
  String? currencyCode;
  double? minAmount;
  double? maxAmount;
  Set<String> tags;
  TransactionSort sort;

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      datePreset != null ||
      customStart != null ||
      customEnd != null ||
      types.isNotEmpty ||
      category != null ||
      accountId != null ||
      currencyCode != null ||
      minAmount != null ||
      maxAmount != null ||
      tags.isNotEmpty;

  TransactionFilterState copy() {
    return TransactionFilterState(
      searchQuery: searchQuery,
      datePreset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
      types: Set.of(types),
      category: category,
      accountId: accountId,
      currencyCode: currencyCode,
      minAmount: minAmount,
      maxAmount: maxAmount,
      tags: Set.of(tags),
      sort: sort,
    );
  }

  void clear() {
    searchQuery = '';
    datePreset = null;
    customStart = null;
    customEnd = null;
    types = {};
    category = null;
    accountId = null;
    currencyCode = null;
    minAmount = null;
    maxAmount = null;
    tags = {};
  }
}
