import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../config/design_tokens.dart';
import '../../models/transaction.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../utils/analytics_aggregations.dart';
import '../home/dashboard/dashboard_section_header.dart';
import '../home/monthly_analytics_card.dart' show CategoryPieChart;
import 'widgets/analytics_section_card.dart';
import 'widgets/category_mini_trend.dart';

/// "Where the money went" — donut chart on top, expandable category rows
/// underneath. Tap a row to inspect related transactions and the 6-month
/// micro trend.
class ExpenseBreakdownSection extends StatefulWidget {
  const ExpenseBreakdownSection({
    super.key,
    required this.slices,
    required this.range,
    required this.allTransactions,
    required this.onTapTransaction,
  });

  final List<CategorySlice> slices;
  final ResolvedRange range;
  final List<Transaction> allTransactions;
  final void Function(Transaction transaction) onTapTransaction;

  @override
  State<ExpenseBreakdownSection> createState() =>
      _ExpenseBreakdownSectionState();
}

class _ExpenseBreakdownSectionState extends State<ExpenseBreakdownSection> {
  String? _expandedCategory;

  @override
  Widget build(BuildContext context) {
    final slices = widget.slices;
    if (slices.isEmpty) {
      return _EmptyBreakdownCard();
    }
    final total = slices.fold<double>(0, (sum, s) => sum + s.total);
    final categoryTotals = {
      for (final slice in slices) slice.category: slice.total,
    };
    final entries = slices
        .map((s) => MapEntry<String, double>(s.category, s.total))
        .toList(growable: false);
    final catalog = CategoryCatalog.instance;
    Color colorForCategory(String name) => catalog.colorForName(name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Where it went',
          subtitle: 'Tap a category to see the story behind it.',
        ),
        const SizedBox(height: AppSpacing.md),
        AnalyticsSectionCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 168,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: CategoryPieChart(
                        categoryTotals: categoryTotals,
                        sortedEntries: entries,
                        total: total,
                        colorForCategory: colorForCategory,
                        trackColor: AppColors.background,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 7,
                      child: _BreakdownLegend(
                        slices: slices,
                        total: total,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < slices.length; i++) ...[
                _CategoryRow(
                  slice: slices[i],
                  isExpanded: slices[i].category == _expandedCategory,
                  onTap: () {
                    setState(() {
                      _expandedCategory = _expandedCategory == slices[i].category
                          ? null
                          : slices[i].category;
                    });
                  },
                  builder: () {
                    return _CategoryDetail(
                      slice: slices[i],
                      range: widget.range,
                      transactions: widget.allTransactions,
                      onTapTransaction: widget.onTapTransaction,
                    );
                  },
                ),
                if (i != slices.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                    indent: 42,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownLegend extends StatelessWidget {
  const _BreakdownLegend({
    required this.slices,
    required this.total,
  });

  final List<CategorySlice> slices;
  final double total;

  @override
  Widget build(BuildContext context) {
    final visible = slices.take(4).toList();
    final catalog = CategoryCatalog.instance;
    final currency = CurrencySettings.instance;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slice in visible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: catalog.colorForName(slice.category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    slice.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(slice.share * 100).round()}%',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        if (slices.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '+${slices.length - 4} more',
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          )
        else if (total > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Total ${currency.formatCompact(total)}',
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.slice,
    required this.isExpanded,
    required this.onTap,
    required this.builder,
  });

  final CategorySlice slice;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    final color = CategoryCatalog.instance.colorForName(slice.category);
    final icon = CategoryCatalog.instance.iconForName(slice.category);
    final currency = CurrencySettings.instance;
    final deltaLabel = _deltaLabel(slice.deltaPct);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withAlpha(32),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slice.category,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          deltaLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: _deltaColor(slice.deltaPct),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.formatCompact(slice.total),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(slice.share * 100).round()}% · '
                        '${slice.transactionCount} txn'
                        '${slice.transactionCount == 1 ? '' : 's'}',
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    duration: AppDurations.short,
                    turns: isExpanded ? 0.5 : 0,
                    curve: AppCurves.spring,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: slice.share.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.background,
                  color: color,
                ),
              ),
              AnimatedSize(
                duration: AppDurations.short,
                curve: AppCurves.spring,
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: builder(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _deltaLabel(double? delta) {
    if (delta == null) return 'no prior data';
    final pct = (delta.abs() * 100).round();
    if (pct < 3) return 'steady vs last period';
    final dir = delta >= 0 ? 'up' : 'down';
    return '$dir $pct% vs last period';
  }

  Color _deltaColor(double? delta) {
    if (delta == null) return AppColors.textSecondary;
    if (delta.abs() < 0.05) return AppColors.textSecondary;
    return delta >= 0 ? AppColors.warning : AppColors.success;
  }
}

class _CategoryDetail extends StatelessWidget {
  const _CategoryDetail({
    required this.slice,
    required this.range,
    required this.transactions,
    required this.onTapTransaction,
  });

  final CategorySlice slice;
  final ResolvedRange range;
  final List<Transaction> transactions;
  final void Function(Transaction tx) onTapTransaction;

  @override
  Widget build(BuildContext context) {
    final color = CategoryCatalog.instance.colorForName(slice.category);
    final monthly = AnalyticsAggregations.categoryMonthlyTrend(
      transactions: transactions,
      category: slice.category,
      months: 6,
    );
    final inRange = AnalyticsAggregations.transactionsForCategory(
      transactions: transactions,
      range: range,
      category: slice.category,
    ).take(3).toList();
    final insightText = _insight(slice);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  insightText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '6-month trend',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CategoryMiniTrend(
                  monthlyTotals: monthly,
                  color: color,
                ),
              ),
            ],
          ),
          if (inRange.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Recent in this period',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final tx in inRange)
              _MiniTransactionRow(
                transaction: tx,
                onTap: () => onTapTransaction(tx),
              ),
          ],
        ],
      ),
    );
  }

  String _insight(CategorySlice slice) {
    final pctOfTotal = (slice.share * 100).round();
    final delta = slice.deltaPct;
    final base = '${slice.category} took $pctOfTotal% of your outflow.';
    if (delta == null) return base;
    final pct = (delta.abs() * 100).round();
    if (pct < 5) return '$base Spending is steady vs last period.';
    if (delta >= 0) {
      return '$base Spending climbed $pct% vs last period — worth a glance.';
    }
    return '$base Spending eased $pct% — nice trim.';
  }
}

class _MiniTransactionRow extends StatelessWidget {
  const _MiniTransactionRow({
    required this.transaction,
    required this.onTap,
  });

  final Transaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final dateLabel = intl.DateFormat.MMMd().format(transaction.date);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  transaction.counterpartyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                dateLabel,
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '-${currency.formatCompact(transaction.amount)}',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBreakdownCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: 'Where it went',
        ),
        const SizedBox(height: AppSpacing.md),
        AnalyticsSectionCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'No spending in this window yet — categories will appear as you log expenses.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
