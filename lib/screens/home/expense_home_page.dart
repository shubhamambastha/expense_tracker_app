import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/common/compact_header.dart';
import '../../components/dialogs/add_account_dialog.dart';
import '../../components/home/dashboard/dashboard_intents.dart';
import '../../components/home/home_content.dart';
import '../../components/home/transactions_content.dart';
import '../../components/recurring/add_recurring_sheet.dart';
import '../../components/transaction/transaction_detail_sheet.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../models/transaction.dart';
import '../../models/transaction_draft.dart';
import '../../services/category_budget_service.dart';
import '../../services/income_category_catalog.dart';
import '../../services/settings_preferences.dart';
import '../../services/app_launch_intent.dart';
import '../../services/deep_link_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/financial_insights.dart';
import '../../utils/recurring_management.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/transaction_subtype_helpers.dart';
import '../analytics/analytics_page.dart';
import '../recurring/recurring_payments_page.dart';
import '../settings/sections/budgets_and_spending_page.dart';
import '../settings/settings_page.dart';
import '../transaction/add_transaction_page.dart';

/// Home page for viewing and managing expenses
class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final List<Transaction> _transactions = [];
  final List<Account> _accounts = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  bool _addTransactionRouteOpen = false;
  final List<Timer> _launchIntentTimers = [];

  @override
  void initState() {
    super.initState();
    CategoryBudgetService.instance.addListener(_onBudgetsChanged);
    AppLaunchIntentHolder.instance.pending.addListener(_onLaunchIntentChanged);
    _scheduleLaunchIntentChecks();
    _loadTransactions();
  }

  @override
  void dispose() {
    for (final timer in _launchIntentTimers) {
      timer.cancel();
    }
    _launchIntentTimers.clear();
    CategoryBudgetService.instance.removeListener(_onBudgetsChanged);
    AppLaunchIntentHolder.instance.pending.removeListener(_onLaunchIntentChanged);
    super.dispose();
  }

  /// Widget URLs can arrive slightly after the first frame; poll briefly.
  void _scheduleLaunchIntentChecks() {
    for (final delay in const [
      Duration.zero,
      Duration(milliseconds: 200),
      Duration(milliseconds: 600),
      Duration(milliseconds: 1200),
    ]) {
      _launchIntentTimers.add(
        Timer(delay, () {
          if (!mounted) return;
          unawaited(DeepLinkService.instance.captureLinks());
          _tryHandleLaunchIntent();
        }),
      );
    }
  }

  void _onLaunchIntentChanged() {
    _tryHandleLaunchIntent();
  }

  void _tryHandleLaunchIntent() {
    if (!mounted || _isLoading || _addTransactionRouteOpen) return;
    if (AppLaunchIntentHolder.instance.consume() == AppLaunchIntent.addExpense) {
      _openAddTransactionPage(kind: TransactionKind.expense);
    }
  }

  void _onBudgetsChanged() {
    if (mounted) setState(() {});
  }

  void _onNavItemTapped(int index) {
    if (index == 2) {
      _openAddTransactionPage();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBottomBarItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final fg =
        isSelected ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => _onNavItemTapped(index),
        borderRadius: AppRadii.buttonRadius,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          curve: AppCurves.spring,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withAlpha(28)
                : Colors.transparent,
            borderRadius: AppRadii.buttonRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: fg,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await SupabaseService.fetchTransactions();
      List<Account> accounts = [];
      try {
        accounts = await SupabaseService.fetchAccounts();
      } catch (error) {
        if (mounted) {
          SnackbarHelper.showMessage(
            context,
            'Could not load accounts: $error',
          );
        }
      }
      try {
        await CategoryBudgetService.instance.refresh();
      } catch (_) {
        // Non-fatal: dashboard simply renders no budgets.
      }
      if (!mounted) return;
      setState(() {
        _transactions
          ..clear()
          ..addAll(transactions);
        _accounts
          ..clear()
          ..addAll(accounts);
        _isLoading = false;
      });
      _scheduleLaunchIntentChecks();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _scheduleLaunchIntentChecks();
      SnackbarHelper.showMessage(
        context,
        '${AppConstants.errorFailedToLoadExpenses}: $error',
      );
    }
  }

  Future<void> _refreshDashboard() => _loadTransactions();

  Future<void> _insertTransaction(Transaction transaction) async {
    try {
      final saved = await SupabaseService.insertTransaction(transaction);
      if (!mounted) return;
      setState(() {
        _transactions.insert(0, saved);
      });
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Transaction saved');
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showMessage(
        context,
        '${AppConstants.errorFailedToSaveExpense}: $error',
      );
    }
  }

  Future<void> _replaceTransaction(Transaction transaction) async {
    try {
      final updated = await SupabaseService.updateTransaction(transaction);
      if (!mounted) return;
      setState(() {
        final idx = _transactions.indexWhere((t) => t.id == transaction.id);
        if (idx >= 0) _transactions[idx] = updated;
      });
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, AppConstants.expenseUpdated);
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showMessage(
        context,
        '${AppConstants.errorFailedToUpdateExpense}: $error',
      );
    }
  }

  Future<void> _saveAccount(Account account) async {
    try {
      final savedAccount = await SupabaseService.insertAccount(account);
      if (!mounted) return;
      setState(() {
        _accounts.add(savedAccount);
        _accounts.sort((a, b) => a.name.compareTo(b.name));
      });
      SnackbarHelper.showSuccess(context, 'Account saved successfully');
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showMessage(context, 'Could not save account: $error');
    }
  }

  void _openAddTransactionPage({
    TransactionDraft? initialDraft,
    TransactionKind? kind,
  }) {
    final draft = initialDraft ??
        TransactionDraft(
          kind: kind ?? TransactionKind.expense,
          accountId: _accounts.isEmpty ? null : _accounts.first.id,
        );
    if (kind != null && initialDraft == null) {
      draft.kind = kind;
    }

    _addTransactionRouteOpen = true;
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute(
            builder: (context) => AddTransactionPage(
              accounts: _accounts,
              recentSuggestions: _buildRecentSuggestions(),
              recentCategoryNames: _buildRecentCategoryNames(),
              recentIncomeSuggestions: _buildRecentIncomeSuggestions(),
              recentIncomeCategoryNames: _buildRecentIncomeCategoryNames(),
              recentPayers: _buildRecentPayers(),
              initialDraft: draft,
              onAddAccount: _openAddAccountDialog,
              onSave: _saveTransactionDraft,
            ),
          ),
        )
        .whenComplete(() {
          if (mounted) {
            _addTransactionRouteOpen = false;
          }
        });
  }

  Future<void> _saveTransactionDraft(TransactionDraft draft) async {
    final account = _accounts.firstWhere(
      (a) => a.id == draft.accountId,
      orElse: () => _accounts.first,
    );
    Account? transferTo;
    if (draft.transferToAccountId != null) {
      for (final a in _accounts) {
        if (a.id == draft.transferToAccountId) {
          transferTo = a;
          break;
        }
      }
    }
    final tx = draft.toTransaction(
      account: account,
      transferToAccount: transferTo,
    );
    if (draft.isEditing) {
      await _replaceTransaction(tx);
    } else {
      await _insertTransaction(tx);
    }
  }

  /// Build "Recent" merchant suggestions from the local expense cache.
  /// Returns the 5 most-recent unique merchants for fast autofill.
  List<RecentSuggestion> _buildRecentSuggestions() {
    final seen = <String>{};
    final out = <RecentSuggestion>[];
    for (final t in _transactions.where((t) => t.isExpense)) {
      final key = t.counterpartyName.toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(RecentSuggestion(
        merchant: t.counterpartyName,
        category: t.category ?? 'Other',
        accountId: t.accountId,
        amount: t.amount,
      ));
      if (out.length >= 5) break;
    }
    return out;
  }

  /// Prioritise the 6 most-used categories so they land first in the pills.
  List<String> _buildRecentCategoryNames() {
    final counts = <String, int>{};
    for (final t in _transactions.where((t) => t.isExpense)) {
      final cat = t.category ?? 'Other';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).map((e) => e.key).toList();
  }

  List<RecentSuggestion> _buildRecentIncomeSuggestions() {
    final seen = <String>{};
    final out = <RecentSuggestion>[];
    for (final t in _transactions.where((t) => t.isIncome)) {
      final key = t.counterpartyName.toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(RecentSuggestion(
        merchant: t.counterpartyName,
        category: t.category ?? 'Other',
        accountId: t.accountId,
        amount: t.amount,
        kind: TransactionKind.income,
        recurring: t.isRecurring
            ? RecurringConfig(
                enabled: true,
                frequency:
                    t.recurrenceFrequency ?? RecurrenceFrequency.monthly,
                endDate: t.recurrenceEndDate,
              )
            : null,
      ));
      if (out.length >= 5) break;
    }
    if (out.isNotEmpty) return out;
    return const [
      RecentSuggestion(
        merchant: 'Company XYZ',
        category: 'Salary',
        kind: TransactionKind.income,
      ),
    ];
  }

  List<String> _buildRecentIncomeCategoryNames() {
    final counts = <String, int>{};
    for (final t in _transactions.where((t) => t.isIncome)) {
      final cat = t.category;
      if (cat == null) continue;
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return IncomeCategoryCatalog.instance.names.take(6).toList();
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).map((e) => e.key).toList();
  }

  List<String> _buildRecentPayers() {
    final seen = <String>{};
    final out = <String>[];
    for (final t in _transactions.where((t) => t.isIncome)) {
      final payer = t.counterpartyName.trim();
      if (payer.isEmpty || !seen.add(payer.toLowerCase())) continue;
      out.add(payer);
      if (out.length >= 8) break;
    }
    if (out.isNotEmpty) return out;
    return const ['Company XYZ', 'Acme Corp'];
  }

  void _openEditTransaction(Transaction transaction) {
    _openAddTransactionPage(initialDraft: transaction.toDraft());
  }

  void _convertToRecurring(Transaction transaction) {
    final draft = transaction.toDraft();
    draft.recurring = draft.recurring.copyWith(enabled: true);
    _openAddTransactionPage(initialDraft: draft);
  }

  Future<void> _confirmAndDeleteTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.counterpartyName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await SupabaseService.deleteTransaction(transaction.id!);
      if (!mounted) return;
      setState(() => _transactions.removeWhere((t) => t.id == transaction.id));
      SnackbarHelper.showSuccess(context, AppConstants.expenseDeleted);
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showMessage(
        context,
        '${AppConstants.errorFailedToDeleteExpense}: $error',
      );
    }
  }

  Future<void> _duplicateTransaction(Transaction transaction) async {
    final copy = transaction.copyWith(
      id: null,
      date: DateTime.now(),
    );
    await _insertTransaction(copy);
  }

  Widget _buildHomeContent(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        SettingsPreferences.instance,
        CategoryBudgetService.instance,
      ]),
      builder: (context, _) {
        return HomeContent(
          transactions: _transactions,
          accounts: _accounts,
          monthlyLimit: SettingsPreferences.instance.monthlySpendingLimit,
          userEmail: SupabaseService.currentUser?.email,
          isLoading: _isLoading,
          onRefresh: _refreshDashboard,
          onQuickAction: _handleQuickAction,
          onTapTransaction: _openTransactionDetail,
          onViewAllTransactions: () => _switchToTab(1),
          onManageAccounts: () => _switchToTab(4),
          onOpenBudgetSettings: _openBudgetSettings,
          onTapAccount: _openAccountTransactions,
        );
      },
    );
  }

  void _switchToTab(int index) {
    if (index < 0 || index > 4 || index == 2) return;
    setState(() => _selectedIndex = index);
  }

  void _handleQuickAction(QuickAction action) {
    switch (action) {
      case QuickAction.addExpense:
        _openAddTransactionPage(kind: TransactionKind.expense);
        return;
      case QuickAction.addIncome:
        _openAddTransactionPage(kind: TransactionKind.income);
        return;
      case QuickAction.transfer:
        _openAddTransactionPage(kind: TransactionKind.transfer);
        return;
      case QuickAction.addEmi:
        final draft = TransactionDraft(
          kind: TransactionKind.expense,
          accountId: _accounts.isEmpty ? null : _accounts.first.id,
        );
        TransactionSubtypeHelpers.applyExpenseSubtype(
          draft,
          TransactionSubtypeHelpers.expenseCategoryEmi,
        );
        _openAddTransactionPage(initialDraft: draft);
        return;
    }
  }

  void _openTransactionDetail(Transaction transaction) {
    showTransactionDetailSheet(
      context: context,
      transaction: transaction,
      account: _accountFor(transaction.accountId),
      transferToAccount: _accountFor(transaction.transferToAccountId),
      onEdit: () => _openEditTransaction(transaction),
      onDuplicate: () => _duplicateTransaction(transaction),
      onConvertToRecurring: () => _convertToRecurring(transaction),
      onDelete: () => _confirmAndDeleteTransaction(transaction),
    );
  }

  Account? _accountFor(int? id) {
    if (id == null) return null;
    for (final account in _accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  void _openAccountTransactions(Account account) {
    _switchToTab(1);
  }

  Future<void> _openBudgetSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const BudgetsAndSpendingPage(),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  void _handleInsightAction(FinancialInsight insight) {
    final payload = insight.actionPayload ?? '';
    if (payload.startsWith('filter:') || payload.startsWith('budget:')) {
      _switchToTab(1);
    }
  }

  Widget _buildTransactionsContent(BuildContext context) {
    return TransactionsContent(
      transactions: _transactions,
      accounts: _accounts,
      isLoading: _isLoading,
      onEdit: _openEditTransaction,
      onDelete: _confirmAndDeleteTransaction,
      onDuplicate: _duplicateTransaction,
      onConvertToRecurring: _convertToRecurring,
      onAddTransaction: () => _openAddTransactionPage(),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        SettingsPreferences.instance,
        CategoryBudgetService.instance,
      ]),
      builder: (context, _) {
        return AnalyticsPage(
          transactions: _transactions,
          accounts: _accounts,
          categoryBudgets: CategoryBudgetService.instance.budgets,
          isLoading: _isLoading,
          onRefresh: _refreshDashboard,
          onAddTransaction: () => _openAddTransactionPage(),
          onTapTransaction: _openTransactionDetail,
          onOpenBudgetSettings: _openBudgetSettings,
          onInsightAction: _handleInsightAction,
          onOpenRecurringManager: _openRecurringManager,
        );
      },
    );
  }

  Future<void> _openRecurringManager() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RecurringPaymentsPage(
          initialTransactions: _transactions,
          accounts: _accounts,
          monthlyIncome: _currentMonthIncome(),
          onTapTransaction: _openTransactionDetail,
          onAddRecurring: _openAddRecurringFromManager,
          onMutation: _refreshDashboard,
        ),
      ),
    );
    if (!mounted) return;
    // The manager may have mutated transactions/events — pull the freshest
    // snapshot so home / analytics / settings reflect the changes too.
    await _refreshDashboard();
  }

  /// Wraps [_openAddTransactionPage] so the manager screen's "+" sheet can
  /// kick off an add flow with the right kind preselected.
  Future<void> _openAddRecurringFromManager(RecurringKind kind) async {
    final draft = TransactionDraft(
      accountId: _accounts.isEmpty ? null : _accounts.first.id,
    );
    applyDraftFor(draft, kind);
    _openAddTransactionPage(initialDraft: draft);
  }

  /// Sums the current calendar-month income — fed to the manager's Payment
  /// Insights section so it can render the "EMIs consume X% of income" line.
  double? _currentMonthIncome() {
    final now = DateTime.now();
    final total = _transactions
        .where((t) =>
            t.isIncome &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold<double>(0, (sum, t) => sum + t.amount);
    return total > 0 ? total : null;
  }

  void _openAddAccountDialog({AccountType initialType = AccountType.bank}) {
    showAddAccountDialog(
      context,
      initialType: initialType,
      onSave: _saveAccount,
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    return SettingsPage(
      accounts: _accounts,
      transactions: _transactions,
      onAddAccount: _openAddAccountDialog,
      onSignOut: widget.onSignOut,
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_selectedIndex) {
      case 1:
        return _buildTransactionsContent(context);
      case 3:
        return _buildAnalyticsContent(context);
      case 4:
        return _buildSettingsContent(context);
      case 0:
      default:
        return _buildHomeContent(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CompactHeader(),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDurations.page,
              switchInCurve: AppCurves.emphasized,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: _buildBody(context),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBottomBarItem(
                icon: Icons.dashboard_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildBottomBarItem(
                icon: Icons.list_alt_rounded,
                label: 'Transactions',
                index: 1,
              ),
              _AddExpenseFab(onTap: () => _openAddTransactionPage()),
              _buildBottomBarItem(
                icon: Icons.insights_rounded,
                label: 'Analytics',
                index: 3,
              ),
              _buildBottomBarItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddExpenseFab extends StatelessWidget {
  const _AddExpenseFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.buttonRadius,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadii.buttonRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Color(0xFF002820),
          size: 26,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.04,
          duration: const Duration(milliseconds: 1800),
          curve: Curves.easeInOut,
        );
  }
}

