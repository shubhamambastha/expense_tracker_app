import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/category_budget.dart';
import '../../models/transaction.dart';
import '../../utils/analytics_aggregations.dart';
import '../../utils/financial_insights.dart';
import 'analytics_empty_state.dart';
import 'analytics_header.dart';
import 'behavioral_insights_section.dart';
import 'budget_analytics_section.dart';
import 'expense_breakdown_section.dart';
import 'income_vs_expense_section.dart';
import 'spending_overview_section.dart';
import 'subscriptions_section.dart';
import 'time_range_selector.dart';
import 'trend_analysis_section.dart';

/// Stateful container that owns the [AnalyticsRange] selection and re-derives
/// every section's data when the user changes the period.
///
/// Aggregations run synchronously during build today — fast enough for the
/// in-memory transaction list — but the helpers in
/// [AnalyticsAggregations] are pure so we can move them to an isolate (or
/// memoise per-range) without touching the section widgets.
class AnalyticsContent extends StatefulWidget {
  const AnalyticsContent({
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
    this.onOpenRecurringManager,
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

  /// When set, the Subscriptions & Recurring card surfaces a "View all"
  /// link that pushes the dedicated Recurring Payments Manager screen.
  final VoidCallback? onOpenRecurringManager;

  @override
  State<AnalyticsContent> createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends State<AnalyticsContent> {
  AnalyticsRange _range = AnalyticsRange.thisMonth;
  ResolvedRange? _customRange;

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 3, 1, 1);
    final initial = _customRange ??
        ResolvedRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initial.start,
        end: initial.end,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _range = AnalyticsRange.custom;
      _customRange = ResolvedRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading &&
        widget.transactions.isEmpty &&
        widget.accounts.isEmpty) {
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

    final resolved = _range.resolve(customRange: _customRange);
    final isEmptyAccount =
        widget.transactions.isEmpty && widget.accounts.isEmpty;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
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
              children: isEmptyAccount
                  ? _onboarding(resolved)
                  : _sections(resolved),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _onboarding(ResolvedRange resolved) {
    return [
      AnalyticsHeader(
        range: _range,
        resolvedRange: resolved,
      ),
      const SizedBox(height: AppSpacing.lg),
      TimeRangeSelector(
        selected: _range,
        onChanged: (next) => setState(() => _range = next),
        onPickCustom: _pickCustomRange,
      ),
      const SizedBox(height: AppSpacing.xxl),
      AnalyticsEmptyState(onAddTransaction: widget.onAddTransaction),
    ];
  }

  List<Widget> _sections(ResolvedRange resolved) {
    final transactions = widget.transactions;
    final overview = AnalyticsAggregations.overview(
      transactions: transactions,
      range: resolved,
    );
    final slices = AnalyticsAggregations.categoryBreakdown(
      transactions: transactions,
      range: resolved,
    );
    final buckets = AnalyticsAggregations.incomeVsExpenseBuckets(
      transactions: transactions,
      range: resolved,
    );
    final recurring = AnalyticsAggregations.recurringSummary(
      transactions: transactions,
    );
    final budgetSpend = AnalyticsAggregations.budgetSpend(
      transactions: transactions,
      budgets: widget.categoryBudgets,
      range: resolved,
    );
    final weekdayAverages = AnalyticsAggregations.weekdayProfile(
      transactions: transactions,
      range: resolved,
    );
    final longTrend = AnalyticsAggregations.longTermTrend(
      transactions: transactions,
      months: 12,
    );
    final insights = generateInsights(
      transactions: transactions,
      budgets: widget.categoryBudgets,
    );

    return [
      AnalyticsHeader(
        range: _range,
        resolvedRange: resolved,
      ),
      const SizedBox(height: AppSpacing.lg),
      TimeRangeSelector(
        selected: _range,
        onChanged: (next) => setState(() => _range = next),
        onPickCustom: _pickCustomRange,
      ),
      const SizedBox(height: AppSpacing.xxl),
      SpendingOverviewSection(
        overview: overview,
        rangeLabel: _range.label,
      ),
      const SizedBox(height: AppSpacing.xxl),
      ExpenseBreakdownSection(
        slices: slices,
        range: resolved,
        allTransactions: transactions,
        onTapTransaction: widget.onTapTransaction,
      ),
      const SizedBox(height: AppSpacing.xxl),
      IncomeVsExpenseSection(
        buckets: buckets,
        overview: overview,
        rangeIsMultiMonth: _range.isMultiMonth,
      ),
      const SizedBox(height: AppSpacing.xxl),
      BudgetAnalyticsSection(
        budgets: widget.categoryBudgets,
        spendByCategory: budgetSpend,
        onOpenBudgetSettings: widget.onOpenBudgetSettings,
      ),
      const SizedBox(height: AppSpacing.xxl),
      SubscriptionsSection(
        summary: recurring,
        accounts: widget.accounts,
        onTapItem: widget.onTapTransaction,
        onViewAll: widget.onOpenRecurringManager,
      ),
      const SizedBox(height: AppSpacing.xxl),
      BehavioralInsightsSection(
        insights: insights,
        weekdayAverages: weekdayAverages,
        onAction: widget.onInsightAction,
      ),
      const SizedBox(height: AppSpacing.xxl),
      TrendAnalysisSection(buckets: longTrend),
    ];
  }
}
