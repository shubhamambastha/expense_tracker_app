import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/common/compact_header.dart';
import '../../components/dialogs/add_account_dialog.dart';
import '../../components/dialogs/expense_form_dialog.dart';
import '../../components/home/home_content.dart';
import '../../components/home/expenses_content.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../models/transaction_draft.dart';
import '../../services/income_category_catalog.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/snackbar_helper.dart';
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
  final List<Expense> _expenses = [];
  final List<Account> _accounts = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _onNavItemTapped(int index) {
    if (index == 2) {
      _openAddExpenseDialog();
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

    return InkWell(
      onTap: () => _onNavItemTapped(index),
      borderRadius: AppRadii.buttonRadius,
      child: AnimatedContainer(
        duration: AppDurations.micro,
        curve: AppCurves.spring,
        constraints: const BoxConstraints(minWidth: 60),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
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
              style: AppTextStyles.caption.copyWith(
                color: fg,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await SupabaseService.fetchExpenses();
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
      if (!mounted) return;
      setState(() {
        _expenses
          ..clear()
          ..addAll(expenses);
        _accounts
          ..clear()
          ..addAll(accounts);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showMessage(
        context,
        '${AppConstants.errorFailedToLoadExpenses}: $error',
      );
    }
  }

  Future<void> _saveExpense(Expense expense) async {
    try {
      final savedExpense = await SupabaseService.insertExpense(expense);
      if (!mounted) return;
      setState(() {
        _expenses.insert(0, savedExpense);
      });
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Expense saved successfully');
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showMessage(
        context,
        '${AppConstants.errorFailedToSaveExpense}: $error',
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

  void _openAddExpenseDialog() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          accounts: _accounts,
          recentSuggestions: _buildRecentSuggestions(),
          recentCategoryNames: _buildRecentCategoryNames(),
          recentIncomeSuggestions: _buildRecentIncomeSuggestions(),
          recentIncomeCategoryNames: _buildRecentIncomeCategoryNames(),
          recentPayers: _buildRecentPayers(),
          onAddAccount: _openAddAccountDialog,
          onSave: _saveTransactionDraft,
        ),
      ),
    );
  }

  Future<void> _saveTransactionDraft(TransactionDraft draft) async {
    final account = _accounts.firstWhere(
      (a) => a.id == draft.accountId,
      orElse: () => _accounts.first,
    );
    await _saveExpense(draft.toExpense(account: account));
  }

  /// Build "Recent" merchant suggestions from the local expense cache.
  /// Returns the 5 most-recent unique merchants for fast autofill.
  List<RecentSuggestion> _buildRecentSuggestions() {
    final seen = <String>{};
    final out = <RecentSuggestion>[];
    for (final e in _expenses) {
      final key = e.name.toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(RecentSuggestion(
        merchant: e.name,
        category: e.category,
        accountId: e.accountId,
        amount: e.amount,
      ));
      if (out.length >= 5) break;
    }
    return out;
  }

  /// Prioritise the 6 most-used categories so they land first in the pills.
  List<String> _buildRecentCategoryNames() {
    final counts = <String, int>{};
    for (final e in _expenses) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).map((e) => e.key).toList();
  }

  /// Sample income autofill rows until income is persisted separately.
  List<RecentSuggestion> _buildRecentIncomeSuggestions() {
    return [
      RecentSuggestion(
        merchant: 'Company XYZ',
        category: 'Salary',
        amount: 85000,
        kind: TransactionKind.income,
        recurring: RecurringConfig(
          enabled: true,
          frequency: RecurrenceFrequency.monthly,
        ),
      ),
      const RecentSuggestion(
        merchant: 'Amazon',
        category: 'Refund',
        kind: TransactionKind.income,
      ),
      const RecentSuggestion(
        merchant: 'Acme Corp',
        category: 'Freelance',
        kind: TransactionKind.income,
      ),
      const RecentSuggestion(
        merchant: 'Axis Ace',
        category: 'Cashback',
        kind: TransactionKind.income,
      ),
    ];
  }

  List<String> _buildRecentIncomeCategoryNames() {
    return IncomeCategoryCatalog.instance.names.take(6).toList();
  }

  List<String> _buildRecentPayers() {
    return const [
      'Company XYZ',
      'Acme Corp',
      'Amazon',
      'Rahul',
      'Axis Ace',
    ];
  }

  void _openEditExpenseDialog(Expense expense) {
    showDialog<void>(
      context: context,
      builder: (context) => ExpenseFormDialog(
        accounts: _accounts,
        onSave: _updateExpense,
        expense: expense,
      ),
    );
  }

  Future<void> _confirmAndDeleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense'),
        content: Text(
          'Are you sure you want to delete "${expense.name}"?',
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
      await SupabaseService.deleteExpense(expense.id!);
      if (!mounted) return;
      setState(() => _expenses.removeWhere((e) => e.id == expense.id));
      SnackbarHelper.showSuccess(context, AppConstants.expenseDeleted);
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showMessage(
        context,
        '${AppConstants.errorFailedToDeleteExpense}: $error',
      );
    }
  }

  Future<void> _updateExpense(Expense expense) async {
    try {
      final updated = await SupabaseService.updateExpense(expense);
      if (!mounted) return;
      setState(() {
        final idx = _expenses.indexWhere((e) => e.id == expense.id);
        if (idx >= 0) _expenses[idx] = updated;
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

  void _openAddAccountDialog({AccountType initialType = AccountType.bank}) {
    showAddAccountDialog(
      context,
      initialType: initialType,
      onSave: _saveAccount,
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return HomeContent(expenses: _expenses, isLoading: _isLoading);
  }

  Widget _buildExpensesContent(BuildContext context) {
    return ExpensesContent(
      expenses: _expenses,
      accounts: _accounts,
      isLoading: _isLoading,
      onEdit: _openEditExpenseDialog,
      onDelete: _confirmAndDeleteExpense,
    );
  }

  Widget _buildPlaceholderContent(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withAlpha(36),
                  AppColors.secondary.withAlpha(20),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Icon(icon, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Content will be available soon.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    return SettingsPage(
      accounts: _accounts,
      expenses: _expenses,
      onAddAccount: _openAddAccountDialog,
      onSignOut: widget.onSignOut,
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_selectedIndex) {
      case 1:
        return _buildExpensesContent(context);
      case 3:
        return _buildPlaceholderContent('Advise', Icons.psychology);
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
                label: 'Expenses',
                index: 1,
              ),
              _AddExpenseFab(onTap: _openAddExpenseDialog),
              _buildBottomBarItem(
                icon: Icons.insights_rounded,
                label: 'Advise',
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

