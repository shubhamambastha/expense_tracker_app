import 'package:flutter/material.dart';
import '../../models/expense.dart';
import 'expense_summary_card.dart';
import 'expense_list.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key, required this.expenses, required this.isLoading});

  final List<Expense> expenses;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpenseSummaryCard(expenses: expenses),
          const SizedBox(height: 16),
          Expanded(
            child: ExpenseList(expenses: expenses, isLoading: isLoading),
          ),
        ],
      ),
    );
  }
}
