import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../utils/dashboard_aggregations.dart';
import 'dashboard/account_overview_section.dart';
import 'dashboard/dashboard_greeting_header.dart';
import 'dashboard/dashboard_intents.dart';
import 'dashboard/hero_overview_card.dart';
import 'dashboard/quick_actions_row.dart';
import 'dashboard/recent_transactions_section.dart';

/// Behavioral-finance dashboard composed from modular section widgets.
///
/// Aggregations are computed once per build and passed down so each section
/// stays stateless and cheap. Designed to swap onto a Riverpod/Bloc layer
/// later without touching the section widgets themselves.
///
/// Budget progress, behavioural insights, and recurring/upcoming payment
/// summaries live on the Analytics screen (`BudgetAnalyticsSection`,
/// `BehavioralInsightsSection`, `SubscriptionsSection`) so home stays
/// scannable and focused on today/this-month action.
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.userEmail,
    required this.isLoading,
    required this.onRefresh,
    required this.onQuickAction,
    required this.onTapTransaction,
    required this.onViewAllTransactions,
    required this.onManageAccounts,
    required this.onTapAccount,
  });

  final List<Transaction> transactions;
  final List<Account> accounts;
  final String? userEmail;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final void Function(QuickAction action) onQuickAction;
  final void Function(Transaction tx) onTapTransaction;
  final VoidCallback onViewAllTransactions;
  final VoidCallback onManageAccounts;
  final void Function(Account account) onTapAccount;

  @override
  Widget build(BuildContext context) {
    if (isLoading && transactions.isEmpty && accounts.isEmpty) {
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

    final now = DateTime.now();
    final todayBalance =
        DashboardAggregations.todayBalance(transactions, now: now);
    final todayIncome =
        DashboardAggregations.todayIncome(transactions, now: now);
    final todayExpenses =
        DashboardAggregations.todaySpend(transactions, now: now);
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
                      todayBalance: todayBalance,
                      todayIncome: todayIncome,
                      todayExpenses: todayExpenses,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sections({
    required double todayBalance,
    required double todayIncome,
    required double todayExpenses,
  }) {
    return [
      DashboardGreetingHeader(
        userEmail: userEmail,
        onAvatarTap: onManageAccounts,
      ),
      const SizedBox(height: AppSpacing.lg),
      HeroOverviewCard(
        todayBalance: todayBalance,
        todayIncome: todayIncome,
        todayExpenses: todayExpenses,
      ),
      const SizedBox(height: AppSpacing.xxl),
      QuickActionsRow(onAction: onQuickAction),
      const SizedBox(height: AppSpacing.xxl),
      RecentTransactionsSection(
        transactions: transactions,
        accounts: accounts,
        onTap: onTapTransaction,
        onViewAll: onViewAllTransactions,
      ),
      const SizedBox(height: AppSpacing.xxl),
      AccountOverviewSection(
        accounts: accounts,
        transactions: transactions,
        onTapAccount: onTapAccount,
        onManage: onManageAccounts,
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
        onAddTransaction: () => onQuickAction(QuickAction.addExpense),
        onAddAccount: onManageAccounts,
      ),
      const SizedBox(height: AppSpacing.xxl),
      QuickActionsRow(onAction: onQuickAction),
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
        gradient: const LinearGradient(
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
            child: const Icon(
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
