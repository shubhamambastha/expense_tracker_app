import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/expense.dart';
import 'monthly_analytics_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.expenses,
    required this.isLoading,
  });

  final List<Expense> expenses;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthlyAnalyticsCard(expenses: expenses),
        ],
      ),
    );
  }
}
