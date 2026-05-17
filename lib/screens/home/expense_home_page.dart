import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../components/common/compact_header.dart';
import '../../components/dialogs/add_expense_dialog.dart';
// Home content composed via components
import '../../components/home/home_content.dart';
import '../../components/home/expenses_content.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
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
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return MaterialButton(
      minWidth: 60,
      onPressed: () => _onNavItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
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
      builder: (context) => AddExpenseDialog(
        categories: AppConstants.expenseCategories,
        accounts: _accounts,
        onSave: _saveExpense,
      ),
    );
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
    );
  }

  Widget _buildPlaceholderContent(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Content will be available soon.'),
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

  Widget _buildProfileContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.simpleCurrency();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 1,
            color: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(24),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _profileInitial,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileMetric(
                          value: currency.format(_totalAmount),
                          label: 'tracked',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileMetric(
                          value: _expenses.length.toString(),
                          label: 'entries',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ProfileMetric(
                    value: _recurringCount.toString(),
                    label: 'recurring expenses',
                    icon: Icons.repeat_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ProfileAccountsSection(
            accounts: _accounts,
            onAddAccount: _openAddAccountDialog,
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 0,
            color: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _ProfileActionTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change password',
                    subtitle: 'Update your account credentials',
                    onTap: _onChangePassword,
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
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
          ),
        ],
      ),
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
      body: Column(
        children: [
          const CompactHeader(),
          Expanded(child: _buildBody(context)),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildBottomBarItem(
                    icon: Icons.dashboard,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildBottomBarItem(
                    icon: Icons.list_alt,
                    label: 'Expenses',
                    index: 1,
                  ),
                ],
              ),
              Row(
                children: [
                  _buildBottomBarItem(
                    icon: Icons.psychology,
                    label: 'Advise',
                    index: 3,
                  ),
                  _buildBottomBarItem(
                    icon: Icons.person,
                    label: 'Profile',
                    index: 4,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseDialog,
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProfileAccountsSection extends StatelessWidget {
  const _ProfileAccountsSection({
    required this.accounts,
    required this.onAddAccount,
  });

  final List<Account> accounts;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Accounts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Add account',
                  onPressed: onAddAccount,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (accounts.isEmpty)
              Text(
                'Add bank accounts, credit cards, cash wallets, or other sources.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: accounts.map((account) {
                  return _AccountChip(account: account);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(_iconForAccount(account.type), size: 16),
      label: Text(account.name),
      side: BorderSide.none,
      backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(115),
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _iconForAccount(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.other:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(115),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isDestructive ? colorScheme.error : colorScheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: foreground.withAlpha(22),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: foreground, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded, color: foreground),
      onTap: onTap,
    );
  }
}
