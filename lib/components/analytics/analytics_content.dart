import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/category_budget.dart';
import '../../models/transaction.dart';
import '../../models/transaction_draft.dart' show TransactionKind;
import '../../services/category_catalog.dart';
import '../../services/income_category_catalog.dart';
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
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

    final resolved = _range.resolve(customRange: _customRange);
    final isEmptyAccount =
        widget.transactions.isEmpty && widget.accounts.isEmpty;

    if (isEmptyAccount) {
      return _scrollPage(_onboarding(resolved), topPadding: AppSpacing.lg);
    }

    final pages = _pages(resolved);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnalyticsHeader(
                range: _range,
                resolvedRange: resolved,
                onAddTransaction: widget.onAddTransaction,
              ),
              const SizedBox(height: AppSpacing.lg),
              TimeRangeSelector(
                selected: _range,
                onChanged: (next) => setState(() => _range = next),
                onPickCustom: _pickCustomRange,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PageIndicator(
                titles: [for (final p in pages) p.title],
                current: _page,
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              for (final p in pages)
                _scrollPage([p.child], topPadding: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scrollPage(List<Widget> children, {required double topPadding}) {
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
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              topPadding,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            sliver: SliverList.list(children: children),
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
        onAddTransaction: widget.onAddTransaction,
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

  List<_AnalyticsPage> _pages(ResolvedRange resolved) {
    final transactions = widget.transactions;
    final overview = AnalyticsAggregations.overview(
      transactions: transactions,
      range: resolved,
    );
    final slices = AnalyticsAggregations.categoryBreakdown(
      transactions: transactions,
      range: resolved,
    );
    final incomeSlices = AnalyticsAggregations.categoryBreakdown(
      transactions: transactions,
      range: resolved,
      kind: TransactionKind.income,
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
      _AnalyticsPage(
        'Overview',
        SpendingOverviewSection(overview: overview, rangeLabel: _range.label),
      ),
      _AnalyticsPage(
        'Expenses',
        ExpenseBreakdownSection(
          slices: slices,
          range: resolved,
          allTransactions: transactions,
          onTapTransaction: widget.onTapTransaction,
          colorForCategory: CategoryCatalog.instance.colorForName,
          iconForCategory: CategoryCatalog.instance.iconForName,
        ),
      ),
      _AnalyticsPage(
        'Income',
        ExpenseBreakdownSection(
          slices: incomeSlices,
          range: resolved,
          allTransactions: transactions,
          onTapTransaction: widget.onTapTransaction,
          colorForCategory: IncomeCategoryCatalog.instance.colorForName,
          iconForCategory: IncomeCategoryCatalog.instance.iconForName,
          kind: TransactionKind.income,
          title: 'Where it came from',
          subtitle: 'Tap a category to see the story behind it.',
          emptyText:
              'No income in this window yet — categories will appear as you log income.',
        ),
      ),
      _AnalyticsPage(
        'Income vs Expense',
        IncomeVsExpenseSection(
          buckets: buckets,
          overview: overview,
          rangeIsMultiMonth: _range.isMultiMonth,
        ),
      ),
      _AnalyticsPage(
        'Budgets',
        BudgetAnalyticsSection(
          budgets: widget.categoryBudgets,
          spendByCategory: budgetSpend,
          onOpenBudgetSettings: widget.onOpenBudgetSettings,
        ),
      ),
      _AnalyticsPage(
        'Recurring',
        SubscriptionsSection(
          summary: recurring,
          accounts: widget.accounts,
          onTapItem: widget.onTapTransaction,
          onViewAll: widget.onOpenRecurringManager,
        ),
      ),
      _AnalyticsPage(
        'Insights',
        BehavioralInsightsSection(
          insights: insights,
          weekdayAverages: weekdayAverages,
          onAction: widget.onInsightAction,
        ),
      ),
      _AnalyticsPage('Trends', TrendAnalysisSection(buckets: longTrend)),
    ];
  }
}

class _AnalyticsPage {
  const _AnalyticsPage(this.title, this.child);

  final String title;
  final Widget child;
}

/// Dots plus the current page's title, so a swipe-only layout still tells
/// users where they are and how many views there are.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.titles, required this.current});

  final List<String> titles;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titles[current.clamp(0, titles.length - 1)],
            style: AppTextStyles.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (var i = 0; i < titles.length; i++)
          AnimatedContainer(
            duration: AppDurations.short,
            margin: const EdgeInsets.only(left: 5),
            width: i == current ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}
