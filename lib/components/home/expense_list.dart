import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../utils/constants.dart';
import 'expense_list_item.dart';

/// Expense list component - displays list of expenses or empty state
class ExpenseList extends StatelessWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.isLoading,
  });

  final List<Expense> expenses;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (expenses.isEmpty) {
      return Center(
        child: Text(
          AppConstants.noExpensesMessage,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return ExpenseListItem(expense: expenses[index]);
      },
    );
  }
}
