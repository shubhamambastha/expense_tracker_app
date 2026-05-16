import 'package:flutter/material.dart';
import '../../components/dialogs/add_expense_dialog.dart';
import '../../components/home/expense_list.dart';
import '../../components/home/expense_summary_card.dart';
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

  @override
  void initState() {
    super.initState();
    _loadExpenses();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onSignOut,
            tooltip: 'Sign out',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddExpenseDialog,
            tooltip: 'Add expense',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppConstants.signedInAsLabel} $_currentEmail',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ExpenseSummaryCard(expenses: _expenses),
            const SizedBox(height: 16),
            Expanded(
              child: ExpenseList(
                expenses: _expenses,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}
