import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'currency_settings.dart';
import 'guest_store.dart';
import 'supabase_service.dart';

/// Rough counts shown in the "bring these in?" confirm dialog before
/// replaying guest data into a real account.
class GuestMigrationSummary {
  const GuestMigrationSummary({
    required this.transactionCount,
    required this.accountCount,
    required this.earliestDate,
    required this.latestDate,
    required this.totalExpense,
    required this.currencyCode,
  });

  final int transactionCount;
  final int accountCount;
  final DateTime? earliestDate;
  final DateTime? latestDate;
  final double totalExpense;
  final String currencyCode;
}

class GuestMigrationResult {
  const GuestMigrationResult({required this.success, this.error});

  final bool success;
  final Object? error;
}

/// Replays everything in [GuestStore] into the now-authenticated real
/// account, then clears local guest data. All-or-nothing: any failure mid
/// replay rolls back every row this attempt inserted (in reverse dependency
/// order) and leaves [GuestStore] untouched so the user can retry.
///
/// Replay order (parents before children, so FKs can be remapped):
///   accounts -> categories/income categories -> transactions
///   -> recurring events -> category budgets
///
/// Accounts and categories are matched by name against what the target
/// account already has (e.g. from its own `ensureDefaultCategories` seed) —
/// only genuinely new rows get inserted; existing rows are reused by id.
/// User settings are deliberately excluded — replaying them risks silently
/// overwriting an existing account's preferences for very little value.
class GuestMigrationService {
  GuestMigrationService._();

  static final GuestMigrationService instance = GuestMigrationService._();

  Future<GuestMigrationSummary> buildSummary() async {
    final transactions = await GuestStore.instance.fetchTransactions();
    final accounts = await GuestStore.instance.fetchAccounts(includeArchived: true);

    DateTime? earliest;
    DateTime? latest;
    double totalExpense = 0;
    for (final t in transactions) {
      if (earliest == null || t.date.isBefore(earliest)) earliest = t.date;
      if (latest == null || t.date.isAfter(latest)) latest = t.date;
      if (t.isExpense) totalExpense += t.amount;
    }

    return GuestMigrationSummary(
      transactionCount: transactions.length,
      accountCount: accounts.length,
      earliestDate: earliest,
      latestDate: latest,
      totalExpense: totalExpense,
      currencyCode: transactions.isNotEmpty
          ? transactions.first.currencyCode
          : CurrencySettings.instance.currencyCode,
    );
  }

  Future<GuestMigrationResult> migrate() async {
    final insertedAccountIds = <int>[];
    final insertedCategoryIds = <int>[];
    final insertedIncomeCategoryIds = <int>[];
    final insertedTransactionIds = <int>[];
    final insertedRecurringEventIds = <int>[];
    final insertedBudgetIds = <int>[];

    try {
      // --- Accounts (name-matched; linkedAccountId remapped in a 2nd pass
      // since it's a self-reference that may point to an account inserted
      // later in iteration order) ---
      final accountIdMap = <int, int>{};
      final remoteAccounts = await SupabaseService.fetchAccounts(includeArchived: true);
      final remoteAccountByName = {
        for (final a in remoteAccounts) a.name.trim().toLowerCase(): a,
      };
      final localAccounts = await GuestStore.instance.fetchAccounts(includeArchived: true);
      for (final local in localAccounts) {
        final existing = remoteAccountByName[local.name.trim().toLowerCase()];
        if (existing != null) {
          accountIdMap[local.id!] = existing.id!;
          continue;
        }
        final saved = await SupabaseService.insertAccount(
          local.copyWith(id: null, clearLinkedAccountId: true),
        );
        accountIdMap[local.id!] = saved.id!;
        insertedAccountIds.add(saved.id!);
      }
      for (final local in localAccounts) {
        if (local.linkedAccountId == null) continue;
        final newId = accountIdMap[local.id!];
        final newLinkedId = accountIdMap[local.linkedAccountId!];
        if (newId == null || newLinkedId == null) continue;
        if (!insertedAccountIds.contains(newId)) continue; // reused existing, don't touch it
        await SupabaseService.updateAccount(
          local.copyWith(id: newId, linkedAccountId: newLinkedId),
        );
      }

      // --- Expense categories (name-matched) ---
      final categoryIdMap = <int, int>{};
      final remoteCategories = await SupabaseService.ensureDefaultCategories();
      final remoteCategoryByName = {
        for (final c in remoteCategories) c.name.trim().toLowerCase(): c,
      };
      final localCategories = await GuestStore.instance.fetchCategories();
      for (final local in localCategories) {
        final existing = remoteCategoryByName[local.name.trim().toLowerCase()];
        if (existing != null) {
          categoryIdMap[local.id!] = existing.id!;
          continue;
        }
        final saved = await SupabaseService.insertCategory(
          name: local.name,
          iconKey: local.iconKey,
          sortOrder: local.sortOrder,
        );
        categoryIdMap[local.id!] = saved.id!;
        insertedCategoryIds.add(saved.id!);
      }

      // --- Income categories (name-matched, mirrors expense categories) ---
      final remoteIncomeCategories = await SupabaseService.ensureDefaultIncomeCategories();
      final remoteIncomeCategoryByName = {
        for (final c in remoteIncomeCategories) c.name.trim().toLowerCase(): c,
      };
      final localIncomeCategories = await GuestStore.instance.fetchIncomeCategories();
      for (final local in localIncomeCategories) {
        final existing = remoteIncomeCategoryByName[local.name.trim().toLowerCase()];
        if (existing != null) continue;
        final saved = await SupabaseService.insertIncomeCategory(
          name: local.name,
          iconKey: local.iconKey,
          sortOrder: local.sortOrder,
        );
        insertedIncomeCategoryIds.add(saved.id!);
      }

      // --- Transactions (accountId / transferToAccountId remapped) ---
      final transactionIdMap = <int, int>{};
      final localTransactions = await GuestStore.instance.fetchTransactions();
      for (final local in localTransactions) {
        final remapped = local.copyWith(
          id: null,
          accountId: local.accountId != null ? accountIdMap[local.accountId] : null,
          transferToAccountId: local.transferToAccountId != null
              ? accountIdMap[local.transferToAccountId]
              : null,
        );
        final saved = await SupabaseService.insertTransaction(remapped);
        transactionIdMap[local.id!] = saved.id!;
        insertedTransactionIds.add(saved.id!);
      }

      // --- Recurring events (transactionId remapped) ---
      final localEvents = await GuestStore.instance.fetchRecurringEvents();
      for (final local in localEvents) {
        final newTransactionId = transactionIdMap[local.transactionId];
        if (newTransactionId == null) continue; // orphaned locally; nothing to attach to
        final saved = await SupabaseService.insertRecurringEvent(
          local.copyWith(id: null, transactionId: newTransactionId),
        );
        insertedRecurringEventIds.add(saved.id!);
      }

      // --- Category budgets (name-matched via the real upsert's own
      // conflict handling; only track genuinely-new ids for rollback —
      // ponytail: an existing budget for the same category name is
      // overwritten with the guest's value and not restored on rollback,
      // upgrade path: snapshot prior value if this proves to matter) ---
      final localBudgets = await GuestStore.instance.fetchCategoryBudgets();
      final existingBudgetNames = (await SupabaseService.fetchCategoryBudgets())
          .map((b) => b.categoryName.trim().toLowerCase())
          .toSet();
      for (final local in localBudgets) {
        final isNew = !existingBudgetNames.contains(local.categoryName.trim().toLowerCase());
        final saved = await SupabaseService.upsertCategoryBudget(
          local.copyWith(id: null),
        );
        if (isNew) insertedBudgetIds.add(saved.id!);
      }

      await GuestStore.instance.clearEverything();
      await AuthService.instance.exitGuestMode();
      return const GuestMigrationResult(success: true);
    } catch (error) {
      await _rollback(
        accountIds: insertedAccountIds,
        categoryIds: insertedCategoryIds,
        incomeCategoryIds: insertedIncomeCategoryIds,
        transactionIds: insertedTransactionIds,
        recurringEventIds: insertedRecurringEventIds,
        budgetIds: insertedBudgetIds,
      );
      return GuestMigrationResult(success: false, error: error);
    }
  }

  /// Deletes everything inserted this attempt, in reverse dependency order,
  /// so [GuestStore] stays the only place the data exists after a failure.
  Future<void> _rollback({
    required List<int> accountIds,
    required List<int> categoryIds,
    required List<int> incomeCategoryIds,
    required List<int> transactionIds,
    required List<int> recurringEventIds,
    required List<int> budgetIds,
  }) async {
    for (final id in recurringEventIds) {
      await _safely(() => SupabaseService.deleteRecurringEvent(id));
    }
    for (final id in transactionIds) {
      await _safely(() => SupabaseService.deleteTransaction(id));
    }
    for (final id in budgetIds) {
      await _safely(() => SupabaseService.deleteCategoryBudget(id));
    }
    for (final id in incomeCategoryIds) {
      await _safely(() => SupabaseService.deleteIncomeCategory(id));
    }
    for (final id in categoryIds) {
      await _safely(() => SupabaseService.deleteCategory(id));
    }
    for (final id in accountIds) {
      await _safely(() => SupabaseService.deleteAccount(id));
    }
  }

  Future<void> _safely(Future<void> Function() op) async {
    try {
      await op();
    } catch (error) {
      debugPrint('GuestMigrationService rollback step failed: $error');
    }
  }
}
