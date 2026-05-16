import 'package:flutter/material.dart';
import '../../models/expense.dart';
import 'expense_summary_card.dart';
import 'monthly_analytics_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key, required this.expenses, required this.isLoading});

  final List<Expense> expenses;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpenseSummaryCard(expenses: expenses),
          const SizedBox(height: 16),
          MonthlyAnalyticsCard(expenses: expenses),
        ],
      ),
    );
  }
}
