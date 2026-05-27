import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/analytics_aggregations.dart';
import '../home/dashboard/dashboard_section_header.dart';
import 'widgets/analytics_metric_card.dart';
import 'widgets/analytics_section_card.dart';

/// Compact "snapshot" tile: Spent, Income, Saved, Avg/day.
///
/// Stays at four metrics by design — anything more and the screen starts to
/// feel like a BI dashboard.
class SpendingOverviewSection extends StatelessWidget {
  const SpendingOverviewSection({
    super.key,
    required this.overview,
    required this.rangeLabel,
  });

  final AnalyticsOverview overview;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final savings = overview.netSavings;
    final savingsRatePct = overview.savingsRate == null
        ? null
        : (overview.savingsRate! * 100).round();
    final savingsSubtitle = savingsRatePct == null
        ? null
        : '${savingsRatePct.clamp(-999, 999)}% rate';
    final headline = _composeHeadline(currency: currency);

    return AnalyticsSectionCard(
      useGradient: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSectionHeader(
            title: 'Overview',
            subtitle: rangeLabel,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            headline,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AnalyticsMetricCard(
                  label: 'Spent',
                  value: currency.formatCompact(overview.totalSpent),
                  icon: Icons.south_west_rounded,
                  tint: AppColors.danger,
                  delta: overview.spentDelta,
                  deltaPositiveOnIncrease: false,
                  subtitle: 'vs last period',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnalyticsMetricCard(
                  label: 'Income',
                  value: currency.formatCompact(overview.totalIncome),
                  icon: Icons.north_east_rounded,
                  tint: AppColors.success,
                  delta: overview.incomeDelta,
                  deltaPositiveOnIncrease: true,
                  subtitle: 'vs last period',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AnalyticsMetricCard(
                  label: 'Net saved',
                  value: currency.formatCompact(savings),
                  icon: Icons.savings_rounded,
                  tint: savings >= 0 ? AppColors.primary : AppColors.warning,
                  subtitle: savingsSubtitle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnalyticsMetricCard(
                  label: 'Avg / day',
                  value: currency.formatCompact(overview.averageDailySpend),
                  icon: Icons.calendar_view_day_rounded,
                  tint: AppColors.secondary,
                  subtitle: 'spend rhythm',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _composeHeadline({required CurrencySettings currency}) {
    if (overview.totalSpent <= 0 && overview.totalIncome <= 0) {
      return 'Nothing recorded for this period yet.';
    }
    if (overview.totalIncome <= 0) {
      return 'You spent ${currency.formatCompact(overview.totalSpent)} in this window.';
    }
    final rate = overview.savingsRate;
    if (rate != null && rate > 0.2) {
      return 'Saving nicely — ${(rate * 100).round()}% of income kept aside.';
    }
    if (rate != null && rate < 0) {
      return 'Spending outpaced income by '
          '${currency.formatCompact(-overview.netSavings)} in this window.';
    }
    return 'You earned ${currency.formatCompact(overview.totalIncome)} and spent '
        '${currency.formatCompact(overview.totalSpent)}.';
  }
}
