import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/design_tokens.dart';
import '../models/account.dart';
import '../models/expense.dart';
import '../models/recurring_event.dart';
import '../models/transaction.dart';
import '../services/settings_preferences.dart';
import '../models/transaction_draft.dart';
import 'dashboard_aggregations.dart';
import 'recurring_management.dart';

enum AccountSortMode { name, balance, type }

enum AccountWarningTone { none, warning, danger }

/// Credit utilization breakdown for a single card.
class CreditUtilization {
  const CreditUtilization({
    required this.used,
    required this.available,
    required this.limit,
    required this.ratio,
    required this.tone,
  });

  final double used;
  final double available;
  final double? limit;
  final double ratio;
  final AccountWarningTone tone;
}

/// Billing labels derived from statement/due days.
class AccountBillingLabels {
  const AccountBillingLabels({
    this.statementLabel,
    this.dueLabel,
    this.nextStatementLabel,
    this.dueDate,
    this.daysUntilDue,
  });

  final String? statementLabel;
  final String? dueLabel;
  final String? nextStatementLabel;
  final DateTime? dueDate;
  final int? daysUntilDue;
}

/// Top-level snapshot for the accounts list screen.
class AccountManagementSnapshot {
  const AccountManagementSnapshot({
    required this.totalAvailable,
    required this.totalCreditUsed,
    required this.cashAvailable,
    required this.bankAccounts,
    required this.creditCards,
    required this.walletsAndCash,
  });

  final double totalAvailable;
  final double totalCreditUsed;
  final double cashAvailable;
  final List<Account> bankAccounts;
  final List<Account> creditCards;
  final List<Account> walletsAndCash;

  bool get isEmpty =>
      bankAccounts.isEmpty &&
      creditCards.isEmpty &&
      walletsAndCash.isEmpty;
}

class AccountManagement {
  AccountManagement._();

  static AccountManagementSnapshot buildSnapshot({
    required List<Account> accounts,
    required List<Transaction> transactions,
    bool includeArchived = false,
  }) {
    final active = includeArchived
        ? accounts
        : accounts.where((a) => !a.isArchived).toList();

    final bankAccounts =
        active.where((a) => a.type == AccountType.bank).toList();
    final creditCards =
        active.where((a) => a.type == AccountType.creditCard).toList();
    final walletsAndCash = active
        .where(
          (a) =>
              a.type == AccountType.cash ||
              (a.type == AccountType.other && a.isWallet),
        )
        .toList();

    var totalAvailable = 0.0;
    var totalCreditUsed = 0.0;
    var cashAvailable = 0.0;

    for (final account in active) {
      if (account.isCreditCard) {
        totalCreditUsed += creditOutstanding(account, transactions);
      } else {
        final balance = DashboardAggregations.accountBalance(
          account,
          transactions,
        );
        if (account.type == AccountType.cash) {
          cashAvailable += balance.clamp(0, double.infinity);
        }
        if (account.type == AccountType.bank ||
            account.type == AccountType.cash ||
            account.isWallet) {
          totalAvailable += balance.clamp(0, double.infinity);
        }
      }
    }

    return AccountManagementSnapshot(
      totalAvailable: totalAvailable,
      totalCreditUsed: totalCreditUsed,
      cashAvailable: cashAvailable,
      bankAccounts: bankAccounts,
      creditCards: creditCards,
      walletsAndCash: walletsAndCash,
    );
  }

  static List<Account> sortAccounts({
    required List<Account> accounts,
    required List<Transaction> transactions,
    required AccountSortMode mode,
  }) {
    final copy = List<Account>.from(accounts);
    switch (mode) {
      case AccountSortMode.name:
        copy.sort((a, b) => a.displayName.compareTo(b.displayName));
      case AccountSortMode.balance:
        copy.sort((a, b) {
          final balA = _sortBalance(a, transactions);
          final balB = _sortBalance(b, transactions);
          return balB.compareTo(balA);
        });
      case AccountSortMode.type:
        copy.sort((a, b) {
          final typeCmp = a.type.index.compareTo(b.type.index);
          if (typeCmp != 0) return typeCmp;
          return a.displayName.compareTo(b.displayName);
        });
    }
    return copy;
  }

  static double _sortBalance(Account account, List<Transaction> transactions) {
    if (account.isCreditCard) {
      return creditOutstanding(account, transactions);
    }
    return DashboardAggregations.accountBalance(account, transactions);
  }

  /// All-time outstanding on a credit card (not month-to-date).
  static double creditOutstanding(
    Account account,
    List<Transaction> transactions,
  ) {
    if (!account.isCreditCard) return 0;
    final balance = DashboardAggregations.accountBalance(
      account,
      transactions,
    );
    return balance < 0 ? -balance : 0;
  }

  static CreditUtilization creditUtilization(
    Account account,
    List<Transaction> transactions,
  ) {
    final used = creditOutstanding(account, transactions);
    final limit = account.creditLimit;
    final available = limit != null && limit > 0
        ? (limit - used).clamp(0.0, limit).toDouble()
        : 0.0;
    final ratio = limit != null && limit > 0
        ? (used / limit).clamp(0.0, 1.0)
        : 0.0;
    return CreditUtilization(
      used: used,
      available: available,
      limit: limit,
      ratio: ratio,
      tone: _utilizationTone(ratio),
    );
  }

  static AccountWarningTone _utilizationTone(double ratio) {
    if (ratio >= 0.85) return AccountWarningTone.danger;
    if (ratio >= 0.6) return AccountWarningTone.warning;
    return AccountWarningTone.none;
  }

  static Color toneColor(AccountWarningTone tone) {
    switch (tone) {
      case AccountWarningTone.none:
        return AppColors.secondary;
      case AccountWarningTone.warning:
        return AppColors.warning;
      case AccountWarningTone.danger:
        return AppColors.danger;
    }
  }

  static AccountBillingLabels billingLabels(
    Account account, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final statementLabel = account.statementDay != null
        ? 'Statement closes on day ${account.statementDay}'
        : null;

    DateTime? dueDate;
    int? daysUntilDue;
    String? dueLabel;
    if (account.dueDay != null) {
      dueDate = _nextDayOfMonth(account.dueDay!, clock);
      final today = DateTime(clock.year, clock.month, clock.day);
      daysUntilDue = dueDate.difference(today).inDays;
      dueLabel = 'Due ${DateFormat('d MMM').format(dueDate)}';
    }

    String? nextStatementLabel;
    if (account.statementDay != null) {
      final nextStmt = _nextDayOfMonth(account.statementDay!, clock);
      nextStatementLabel =
          'Next statement ${DateFormat('d MMM').format(nextStmt)}';
    }

    return AccountBillingLabels(
      statementLabel: statementLabel,
      dueLabel: dueLabel,
      nextStatementLabel: nextStatementLabel,
      dueDate: dueDate,
      daysUntilDue: daysUntilDue,
    );
  }

  static bool dueSoon(Account account, {DateTime? now}) {
    final labels = billingLabels(account, now: now);
    final days = labels.daysUntilDue;
    return days != null && days >= 0 && days <= 7;
  }

  static bool isDefaultAccount(int? accountId) {
    if (accountId == null) return false;
    return SettingsPreferences.instance.defaultExpenseAccountId == accountId;
  }

  static Account? linkedAccount(
    Account account,
    List<Account> accounts,
  ) {
    final linkedId = account.linkedAccountId;
    if (linkedId == null) return null;
    for (final a in accounts) {
      if (a.id == linkedId) return a;
    }
    return null;
  }

  static List<Transaction> recentTransactionsForAccount(
    Account account,
    List<Transaction> transactions, {
    int limit = 5,
  }) {
    if (account.id == null) return const [];
    final filtered = transactions
        .where(
          (t) =>
              t.accountId == account.id ||
              t.transferToAccountId == account.id,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return filtered.take(limit).toList();
  }

  static Transaction? lastTransactionForAccount(
    Account account,
    List<Transaction> transactions,
  ) {
    final recent = recentTransactionsForAccount(
      account,
      transactions,
      limit: 1,
    );
    return recent.isEmpty ? null : recent.first;
  }

  static double monthSpendForAccount(
    Account account,
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    if (account.id == null) return 0;
    final clock = now ?? DateTime.now();
    return transactions
        .where(
          (t) =>
              t.isExpense &&
              t.accountId == account.id &&
              t.date.year == clock.year &&
              t.date.month == clock.month,
        )
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  static double monthIncomeForAccount(
    Account account,
    List<Transaction> transactions, {
    DateTime? now,
  }) {
    if (account.id == null) return 0;
    final clock = now ?? DateTime.now();
    return transactions
        .where(
          (t) =>
              (t.isIncome || t.kind == TransactionKind.transfer) &&
              (t.accountId == account.id ||
                  t.transferToAccountId == account.id) &&
              t.date.year == clock.year &&
              t.date.month == clock.month,
        )
        .fold<double>(0, (sum, t) {
      if (t.kind == TransactionKind.transfer &&
          t.transferToAccountId == account.id) {
        return sum + t.amount;
      }
      if (t.isIncome && t.accountId == account.id) return sum + t.amount;
      return sum;
    });
  }

  static List<RecurringScheduleItem> linkedSubscriptions(
    Account account,
    List<Transaction> transactions,
    List<RecurringEvent> events,
    List<Account> accounts,
  ) {
    final snapshot = RecurringManagement.build(
      transactions: transactions,
      events: events,
      accounts: accounts,
    );
    return snapshot.subscriptions
        .where((item) => item.transaction.accountId == account.id)
        .toList();
  }

  static List<RecurringScheduleItem> emisForCard(
    Account account,
    List<Transaction> transactions,
    List<RecurringEvent> events,
    List<Account> accounts,
  ) {
    final snapshot = RecurringManagement.build(
      transactions: transactions,
      events: events,
      accounts: accounts,
    );
    return snapshot.emis
        .where((item) => item.transaction.accountId == account.id)
        .toList();
  }

  static bool hasTransactionsForAccount(
    Account account,
    List<Transaction> transactions,
  ) {
    if (account.id == null) return false;
    return transactions.any(
      (t) =>
          t.accountId == account.id || t.transferToAccountId == account.id,
    );
  }

  static IconData iconForAccount(Account account) {
    if (account.isCreditCard) return Icons.credit_card_rounded;
    if (account.type == AccountType.bank) {
      return Icons.account_balance_rounded;
    }
    if (account.type == AccountType.cash) return Icons.payments_rounded;
    return Icons.account_balance_wallet_rounded;
  }

  static String typeLabel(Account account) {
    if (account.isWallet) return account.walletProvider?.label ?? 'Wallet';
    return account.type.label;
  }

  static DateTime _nextDayOfMonth(int day, DateTime reference) {
    var candidate = DateTime(reference.year, reference.month, day);
    final today = DateTime(reference.year, reference.month, reference.day);
    if (candidate.isBefore(today)) {
      candidate = DateTime(reference.year, reference.month + 1, day);
    }
    return candidate;
  }
}
