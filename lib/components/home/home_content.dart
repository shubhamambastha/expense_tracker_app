import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/category_budget.dart';
import '../../models/transaction.dart';
import '../../services/category_budget_service.dart';
import '../../services/settings_preferences.dart';
import '../../utils/analytics_aggregations.dart';
import '../../utils/dashboard_aggregations.dart';
import 'dashboard/budgets_summary_section.dart';
import 'dashboard/dashboard_greeting_header.dart';
import 'dashboard/hero_overview_card.dart';
import 'dashboard/quick_actions_row.dart';
import 'dashboard/recent_transactions_section.dart';
import 'dashboard/spending_room_card.dart';

/// Behavioral-finance dashboard composed from modular section widgets.
///
/// Aggregations are computed once per build and passed down so each section
/// stays stateless and cheap. Designed to swap onto a Riverpod/Bloc layer
/// later without touching the section widgets themselves.
///
/// Behavioural insights and recurring/upcoming payment summaries live on the
/// Analytics screen (`BehavioralInsightsSection`, `SubscriptionsSection`) so
/// home stays scannable and focused on this-month action.
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.userEmail,
    required this.isLoading,
    required this.onRefresh,
    required this.onAddExpense,
    required this.onOpenRecurring,
    required this.onOpenAnalytics,
    required this.onOpenBudgets,
    required this.onTapTransaction,
    required this.onViewAllTransactions,
    required this.onManageAccounts,
  });

  final List<Transaction> transactions;
  final List<Account> accounts;
  final String? userEmail;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddExpense;
  final VoidCallback onOpenRecurring;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenBudgets;
  final void Function(Transaction tx) onTapTransaction;
  final VoidCallback onViewAllTransactions;
  final VoidCallback onManageAccounts;

  @override
  Widget build(BuildContext context) {
    if (isLoading && transactions.isEmpty && accounts.isEmpty) {
      return Center(
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

    final now = DateTime.now();
    final totalBalance = DashboardAggregations.totalBalance(
      accounts,
      transactions,
    );
    final monthIncome = DashboardAggregations.totalMonthIncome(
      transactions,
      now: now,
    );
    final monthSpent = DashboardAggregations.monthSpend(
      transactions,
      now: now,
    );
    final budgets = CategoryBudgetService.instance.budgets;
    final budgetSpend = AnalyticsAggregations.budgetSpend(
      transactions: transactions,
      budgets: budgets,
      range: ResolvedRange(start: DateTime(now.year, now.month), end: now),
    );
    final isOnboarding = transactions.isEmpty && accounts.isEmpty;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            sliver: SliverList.list(
              children: isOnboarding
                  ? _onboarding(context)
                  : _sections(
                      totalBalance: totalBalance,
                      monthIncome: monthIncome,
                      monthSpent: monthSpent,
                      budgets: budgets,
                      budgetSpend: budgetSpend,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sections({
    required double totalBalance,
    required double monthIncome,
    required double monthSpent,
    required List<CategoryBudget> budgets,
    required Map<String, double> budgetSpend,
  }) {
    return [
      DashboardGreetingHeader(
        userEmail: userEmail,
        onAvatarTap: onManageAccounts,
      ),
      const SizedBox(height: AppSpacing.lg),
      HeroOverviewCard(
        totalBalance: totalBalance,
        monthIncome: monthIncome,
        monthSpent: monthSpent,
      ),
      const SizedBox(height: AppSpacing.xxl),
      ListenableBuilder(
        listenable: SettingsPreferences.instance,
        builder: (context, _) {
          if (!SettingsPreferences.instance.safeDailySpendEnabled) {
            return const SizedBox.shrink();
          }
          final now = DateTime.now();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SpendingRoomCard(
                amount: DashboardAggregations.spendableToday(
                  transactions,
                  now: now,
                ),
                hasIncomeThisMonth:
                    DashboardAggregations.totalMonthIncome(
                      transactions,
                      now: now,
                    ) >
                    0,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
      QuickActionsRow(
        onAddExpense: onAddExpense,
        onRecurring: onOpenRecurring,
        onAnalytics: onOpenAnalytics,
      ),
      const SizedBox(height: AppSpacing.xxl),
      BudgetsSummarySection(
        budgets: budgets,
        spendByCategory: budgetSpend,
        onSeeAll: onOpenBudgets,
      ),
      const SizedBox(height: AppSpacing.xxl),
      RecentTransactionsSection(
        transactions: transactions,
        accounts: accounts,
        onTap: onTapTransaction,
        onViewAll: onViewAllTransactions,
      ),
    ];
  }

  List<Widget> _onboarding(BuildContext context) {
    return [
      DashboardGreetingHeader(
        userEmail: userEmail,
        onAvatarTap: onManageAccounts,
      ),
      const SizedBox(height: AppSpacing.lg),
      _OnboardingHero(
        onAddTransaction: onAddExpense,
        onAddAccount: onManageAccounts,
      ),
      const SizedBox(height: AppSpacing.xxl),
      QuickActionsRow(
        onAddExpense: onAddExpense,
        onRecurring: onOpenRecurring,
        onAnalytics: onOpenAnalytics,
      ),
    ];
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({
    required this.onAddTransaction,
    required this.onAddAccount,
  });

  final VoidCallback onAddTransaction;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surfaceSecondary],
        ),
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withAlpha(48),
                  AppColors.secondary.withAlpha(28),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Start tracking expenses',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddTransaction,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Expense'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddAccount,
                  icon: const Icon(Icons.account_balance_rounded),
                  label: const Text('Add Account'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
