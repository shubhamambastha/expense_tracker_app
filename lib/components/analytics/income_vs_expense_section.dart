import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/analytics_aggregations.dart';
import '../home/dashboard/dashboard_section_header.dart';
import 'widgets/analytics_section_card.dart';
import 'widgets/income_expense_bar_chart.dart';

/// "Money in vs money out" — a paired-bar comparison plus the narrative
/// reading underneath (savings rate, net delta, behavioural cue).
class IncomeVsExpenseSection extends StatelessWidget {
  const IncomeVsExpenseSection({
    super.key,
    required this.buckets,
    required this.overview,
    required this.rangeIsMultiMonth,
  });

  final List<PeriodBucket> buckets;
  final AnalyticsOverview overview;
  final bool rangeIsMultiMonth;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final net = overview.netSavings;
    final hasData = overview.totalIncome > 0 || overview.totalSpent > 0;
    final savingsRatePct = overview.savingsRate == null
        ? null
        : (overview.savingsRate! * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Income vs Expense',
          subtitle: rangeIsMultiMonth
              ? 'Monthly buckets — tap a bar for details.'
              : 'Weekly buckets — tap a bar for details.',
        ),
        const SizedBox(height: AppSpacing.md),
        AnalyticsSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasData)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'No income or expenses recorded for this window.',
                    style: AppTextStyles.bodySmall,
                  ),
                )
              else ...[
                IncomeExpenseBarChart(buckets: buckets),
                const SizedBox(height: AppSpacing.lg),
                _InsightRow(
                  overview: overview,
                  rangeIsMultiMonth: rangeIsMultiMonth,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Net',
                        value: currency.formatCompact(net),
                        tone: net >= 0 ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MetricTile(
                        label: 'Savings rate',
                        value: savingsRatePct == null
                            ? '—'
                            : '$savingsRatePct%',
                        tone: (savingsRatePct ?? -1) >= 20
                            ? AppColors.success
                            : (savingsRatePct ?? 0) < 0
                                ? AppColors.danger
                                : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.overview,
    required this.rangeIsMultiMonth,
  });

  final AnalyticsOverview overview;
  final bool rangeIsMultiMonth;

  String _message() {
    final spentDelta = overview.spentDelta;
    final incomeDelta = overview.incomeDelta;
    final rate = overview.savingsRate;

    if (rate != null && rate < 0) {
      return 'Expenses outpaced income — savings dropped into the red.';
    }
    if (spentDelta != null &&
        incomeDelta != null &&
        spentDelta > 0 &&
        spentDelta > incomeDelta + 0.05) {
      return 'Spending is rising faster than income — keep an eye on it.';
    }
    if (rate != null && rate >= 0.25) {
      return 'Savings rate looks healthy — you\'re keeping a quarter or more of each rupee earned.';
    }
    if (incomeDelta != null && incomeDelta > 0.1) {
      return 'Income trended up vs last period — a nice tailwind.';
    }
    return 'Income and expense are tracking close — explore the buckets to find the swing.';
  }

  IconData _icon() {
    if ((overview.savingsRate ?? 0) < 0) return Icons.trending_down_rounded;
    if ((overview.savingsRate ?? 0) >= 0.25) return Icons.savings_rounded;
    return Icons.timeline_rounded;
  }

  Color _tone() {
    final rate = overview.savingsRate;
    if (rate == null) return AppColors.secondary;
    if (rate < 0) return AppColors.danger;
    if (rate >= 0.25) return AppColors.success;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: tone.withAlpha(28),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_icon(), color: tone, size: 16),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            _message(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
