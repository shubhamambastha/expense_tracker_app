import 'package:flutter/material.dart';
import '../../models/expense.dart';
import 'expense_list.dart';

class ExpensesContent extends StatelessWidget {
  const ExpensesContent({super.key, required this.expenses, required this.isLoading});

  final List<Expense> expenses;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ExpenseList(expenses: expenses, isLoading: isLoading),
          ),
        ],
      ),
    );
  }
}
