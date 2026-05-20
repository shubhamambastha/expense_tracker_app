import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import 'expense_list.dart';

class ExpensesContent extends StatelessWidget {
  const ExpensesContent({
    super.key,
    required this.expenses,
    required this.accounts,
    required this.isLoading,
    this.onEdit,
    this.onDelete,
  });

  final List<Expense> expenses;
  final List<Account> accounts;
  final bool isLoading;
  final void Function(Expense expense)? onEdit;
  final void Function(Expense expense)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ExpenseList(
              expenses: expenses,
              accounts: accounts,
              isLoading: isLoading,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
