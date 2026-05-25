import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/common/compact_header.dart';
import '../../components/dialogs/expense_form_dialog.dart';
import '../../components/profile/accounts_settings_section.dart';
import '../../components/profile/categories_settings_section.dart';
import '../../components/home/home_content.dart';
import '../../components/home/expenses_content.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../services/currency_settings.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/snackbar_helper.dart';

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
    showDialog<void>(
      context: context,
      builder: (context) => ExpenseFormDialog(
        accounts: _accounts,
        onSave: _saveExpense,
      ),
    );
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

  void _openAddAccountDialog() {
    final nameController = TextEditingController();
    var selectedType = AccountType.bank;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Account name',
                      hintText: 'HDFC Credit Card',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AccountType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Account type',
                    ),
                    items: AccountType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedType = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      SnackbarHelper.showMessage(
                        context,
                        'Enter an account name',
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    _saveAccount(Account(name: name, type: selectedType));
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(nameController.dispose);
  }

  String get _currentEmail =>
      SupabaseService.currentUser?.email ?? 'Unknown user';

  double get _totalAmount {
    return _expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  int get _recurringCount {
    return _expenses.where((expense) => expense.isRecurring).length;
  }

  String get _profileInitial {
    final email = _currentEmail.trim();
    if (email.isEmpty || email == 'Unknown user') return '?';
    return email.characters.first.toUpperCase();
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

  void _onChangePassword() {
    SnackbarHelper.showMessage(
      context,
      'Change password will be available soon.',
    );
  }

  void _openCurrencyPicker() {
    final settings = CurrencySettings.instance;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final maxSheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final currentCode = settings.currencyCode;

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: Text(
                        'Default currency',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'All amounts are entered and shown in this currency.',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: Theme.of(sheetContext)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: CurrencySettings.supported.length,
                        itemBuilder: (context, index) {
                          final option = CurrencySettings.supported[index];
                          final selected = option.code == currentCode;

                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: selected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              child: Text(
                                option.symbol,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: selected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                ),
                              ),
                            ),
                            title: Text(
                              option.name,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(option.code),
                            trailing: selected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                            onTap: () async {
                              await settings.setCurrency(option.code);
                              setSheetState(() {});
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              if (!mounted) return;
                              setState(() {});
                              SnackbarHelper.showSuccess(
                                context,
                                'Currency set to ${option.name}',
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return ListenableBuilder(
      listenable: CurrencySettings.instance,
      builder: (context, _) {
        final currencySettings = CurrencySettings.instance;

        return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withAlpha(64),
                            AppColors.secondary.withAlpha(32),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(50),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _profileInitial,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile',
                            style: AppTextStyles.headingSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileMetric(
                        value: currencySettings.format(_totalAmount),
                        label: 'tracked',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ProfileMetric(
                        value: _expenses.length.toString(),
                        label: 'entries',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProfileMetric(
                  value: _recurringCount.toString(),
                  label: 'recurring expenses',
                  icon: Icons.repeat_rounded,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: AppDurations.page)
              .slideY(
                begin: 0.04,
                end: 0,
                duration: AppDurations.page,
                curve: AppCurves.spring,
              ),
          const SizedBox(height: AppSpacing.md),
          AccountsSettingsSection(
            accounts: _accounts,
            onAddAccount: _openAddAccountDialog,
          ),
          const SizedBox(height: AppSpacing.md),
          const CategoriesSettingsSection(),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileActionTile(
                  icon: Icons.payments_rounded,
                  title: 'Default currency',
                  subtitle:
                      '${currencySettings.current.name} (${currencySettings.currencyCode})',
                  onTap: _openCurrencyPicker,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
                _ProfileActionTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change password',
                  subtitle: 'Update your account credentials',
                  onTap: _onChangePassword,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
                _ProfileActionTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  subtitle: 'End this session',
                  isDestructive: true,
                  onTap: widget.onSignOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_selectedIndex) {
      case 1:
        return _buildExpensesContent(context);
      case 3:
        return _buildPlaceholderContent('Advise', Icons.psychology);
      case 4:
        return _buildProfileContent(context);
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
                icon: Icons.person_rounded,
                label: 'Profile',
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

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDestructive ? AppColors.danger : AppColors.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: foreground.withAlpha(28),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: foreground, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
