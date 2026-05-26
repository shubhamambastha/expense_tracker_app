import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import '../../../models/account.dart';
import '../../../models/expense.dart';
import '../../../models/transaction.dart';
import '../../../models/transaction_draft.dart';
import '../../../models/transaction_filters.dart';
import '../../../services/category_catalog.dart';
import '../../../services/currency_settings.dart';
import '../../../services/income_category_catalog.dart';
import '../../../utils/transaction_subtype_helpers.dart';

/// Read-only view model for the transaction detail sheet.
class TransactionDetailViewData {
  const TransactionDetailViewData({
    required this.transaction,
    required this.account,
    this.transferToAccount,
    this.tags = const [],
  });

  final Transaction transaction;
  final Account? account;
  final Account? transferToAccount;

  /// Future-ready slot for tags once persisted in the database.
  final List<String> tags;

  factory TransactionDetailViewData.from({
    required Transaction transaction,
    required Account? account,
    Account? transferToAccount,
    List<String> tags = const [],
  }) {
    return TransactionDetailViewData(
      transaction: transaction,
      account: account,
      transferToAccount: transferToAccount,
      tags: tags,
    );
  }

  Transaction get tx => transaction;

  TransactionDisplayType get displayType => displayTypeForTransaction(transaction);

  bool get hasNote =>
      transaction.note != null && transaction.note!.trim().isNotEmpty;

  bool get hasTags => tags.isNotEmpty;

  bool get showNotesSection => hasNote || hasTags;

  bool get showCurrencyMetadata =>
      transaction.currencyCode != CurrencySettings.instance.currencyCode;

  String get amountLabel {
    final formatted = CurrencySettings.instance.format(transaction.amount);
    switch (transaction.kind) {
      case TransactionKind.income:
        return '+$formatted';
      case TransactionKind.expense:
        return '-$formatted';
      case TransactionKind.transfer:
        return formatted;
    }
  }

  Color get amountColor {
    if (transaction.isIncome) return AppColors.success;
    return AppColors.textPrimary;
  }

  String get contextLabel {
    if (transaction.isTransfer) {
      return '${account?.name ?? '?'} → ${transferToAccount?.name ?? '?'}';
    }
    return transaction.counterpartyName;
  }

  String get metaMerchantLabel {
    if (transaction.isTransfer) return 'Transfer';
    return transaction.counterpartyName;
  }

  Color get categoryColor {
    final cat = transaction.category;
    if (transaction.isIncome && cat != null) {
      return IncomeCategoryCatalog.instance.colorForName(cat);
    }
    if (cat != null) {
      return CategoryCatalog.instance.colorForName(cat);
    }
    if (transaction.isTransfer) return AppColors.secondary;
    return AppColors.primary;
  }

  IconData get categoryIcon {
    if (transaction.isTransfer) return Icons.swap_horiz_rounded;
    final cat = transaction.category;
    if (cat != null && transaction.isExpense) {
      return CategoryCatalog.instance.iconForName(cat);
    }
    if (cat != null && transaction.isIncome) {
      return IncomeCategoryCatalog.instance.iconForName(cat);
    }
    return transaction.isIncome
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;
  }

  String? get accountTypeLabel => account?.type.label;

  /// Computes the next recurring payment date from stored recurrence fields.
  DateTime? get nextPaymentDate {
    if (!transaction.isRecurring) return null;
    final frequency =
        transaction.recurrenceFrequency ?? RecurrenceFrequency.monthly;
    final start = transaction.recurrenceStartDate ?? transaction.date;
    final end = transaction.recurrenceEndDate;
    return _computeNextOccurrence(
      start: start,
      frequency: frequency,
      end: end,
    );
  }

  /// Approximate EMI months remaining when category is EMI and end date exists.
  int? get emiRemainingMonths {
    if (!TransactionSubtypeHelpers.isEmiCategory(transaction.category)) {
      return null;
    }
    final end = transaction.recurrenceEndDate;
    if (end == null) return null;

    final now = DateTime.now();
    if (!end.isAfter(now)) return 0;

    final months =
        (end.year - now.year) * 12 + (end.month - now.month);
    return months.clamp(0, 999);
  }
}

DateTime? _computeNextOccurrence({
  required DateTime start,
  required RecurrenceFrequency frequency,
  DateTime? end,
}) {
  final now = DateTime.now();
  var next = start;

  if (next.isAfter(now)) {
    if (end != null && next.isAfter(end)) return null;
    return next;
  }

  for (var i = 0; i < 500; i++) {
    next = _stepForward(next, frequency);
    if (end != null && next.isAfter(end)) return null;
    if (next.isAfter(now)) return next;
  }

  return null;
}

DateTime _stepForward(DateTime date, RecurrenceFrequency frequency) {
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return date.add(const Duration(days: 1));
    case RecurrenceFrequency.weekly:
      return date.add(const Duration(days: 7));
    case RecurrenceFrequency.monthly:
      return DateTime(date.year, date.month + 1, date.day, date.hour,
          date.minute, date.second);
    case RecurrenceFrequency.quarterly:
      return DateTime(date.year, date.month + 3, date.day, date.hour,
          date.minute, date.second);
    case RecurrenceFrequency.yearly:
      return DateTime(date.year + 1, date.month, date.day, date.hour,
          date.minute, date.second);
    case RecurrenceFrequency.custom:
      return date.add(const Duration(days: 30));
  }
}
