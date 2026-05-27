import 'package:flutter/material.dart';

import '../../components/analytics/analytics_content.dart';
import '../../models/account.dart';
import '../../models/category_budget.dart';
import '../../models/transaction.dart';
import '../../utils/financial_insights.dart';

/// Behavioural-finance analytics screen.
///
/// Stateless shell that hands the existing `transactions`, `accounts`, and
/// `categoryBudgets` collections into [AnalyticsContent]. State management
/// (range, custom dates) lives in the content widget so the screen stays
/// agnostic about whether it's hosted from the bottom-nav or pushed as a
/// route later on.
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.categoryBudgets,
    required this.isLoading,
    required this.onRefresh,
    required this.onAddTransaction,
    required this.onTapTransaction,
    required this.onOpenBudgetSettings,
    required this.onInsightAction,
  });

  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<CategoryBudget> categoryBudgets;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddTransaction;
  final void Function(Transaction tx) onTapTransaction;
  final VoidCallback onOpenBudgetSettings;
  final void Function(FinancialInsight insight) onInsightAction;

  @override
  Widget build(BuildContext context) {
    return AnalyticsContent(
      transactions: transactions,
      accounts: accounts,
      categoryBudgets: categoryBudgets,
      isLoading: isLoading,
      onRefresh: onRefresh,
      onAddTransaction: onAddTransaction,
      onTapTransaction: onTapTransaction,
      onOpenBudgetSettings: onOpenBudgetSettings,
      onInsightAction: onInsightAction,
    );
  }
}
