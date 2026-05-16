import 'package:flutter/material.dart';
import '../../components/common/compact_header.dart';
import '../../components/dialogs/add_expense_dialog.dart';
// Home content composed via components
import '../../components/home/home_content.dart';
import '../../components/home/expenses_content.dart';
import '../../models/expense.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/snackbar_helper.dart';

/// Home page for viewing and managing expenses
class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({
    super.key,
    required this.onSignOut,
  });

  final VoidCallback onSignOut;

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final List<Expense> _expenses = [];
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
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;

    return MaterialButton(
      minWidth: 60,
      onPressed: () => _onNavItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
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
      if (!mounted) return;
      setState(() {
        _expenses
          ..clear()
          ..addAll(expenses);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showMessage(context, '${AppConstants.errorFailedToLoadExpenses}: $error');
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
      SnackbarHelper.showMessage(context, '${AppConstants.errorFailedToSaveExpense}: $error');
    }
  }

  void _openAddExpenseDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AddExpenseDialog(
        categories: AppConstants.expenseCategories,
        onSave: _saveExpense,
      ),
    );
  }

  String get _currentEmail => SupabaseService.currentUser?.email ?? 'Unknown user';

  Widget _buildHomeContent(BuildContext context) {
    return HomeContent(expenses: _expenses, isLoading: _isLoading);
  }

  Widget _buildExpensesContent(BuildContext context) {
    return ExpensesContent(expenses: _expenses, isLoading: _isLoading);
  }

  Widget _buildPlaceholderContent(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Content will be available soon.'),
        ],
      ),
    );
  }

  void _onChangePassword() {
    SnackbarHelper.showMessage(context, 'Change password will be available soon.');
  }

  Widget _buildProfileContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${AppConstants.signedInAsLabel} $_currentEmail',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text('Manage your account and sign out from here.'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onChangePassword,
              icon: const Icon(Icons.lock),
              label: const Text('Change password'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseDialog,
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}
