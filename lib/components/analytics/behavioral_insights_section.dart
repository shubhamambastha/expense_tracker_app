import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../utils/financial_insights.dart';
import '../home/dashboard/dashboard_section_header.dart';
import 'widgets/analytics_section_card.dart';
import 'widgets/weekday_profile_chart.dart';

const int kBehavioralInsightsLimit = 4;

/// Conversational nudges + a weekday spending profile. This is the section
/// that gives Analytics its personality — keep the copy human, the visual
/// quiet, and never overwhelm.
class BehavioralInsightsSection extends StatelessWidget {
  const BehavioralInsightsSection({
    super.key,
    required this.insights,
    required this.weekdayAverages,
    required this.onAction,
  });

  final List<FinancialInsight> insights;
  final List<double>? weekdayAverages;
  final void Function(FinancialInsight insight) onAction;

  @override
  Widget build(BuildContext context) {
    final visible = insights.take(kBehavioralInsightsLimit).toList();
    final hasAnything = visible.isNotEmpty || weekdayAverages != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: 'Behavioural Insights',
          subtitle: 'Patterns we noticed across your activity.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (!hasAnything)
          AnalyticsSectionCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Log a few weeks of transactions and we\'ll surface habits, weekday patterns, and lifestyle shifts here.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (weekdayAverages != null) ...[
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
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(28),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_view_week_rounded,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Weekday rhythm',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _weekdayInsight(weekdayAverages!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  WeekdayProfileChart(averages: weekdayAverages!),
                ],
              ),
            ),
            if (visible.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          ],
          if (visible.isNotEmpty)
            for (var i = 0; i < visible.length; i++) ...[
              _InsightCard(
                insight: visible[i],
                onTap: visible[i].actionLabel == null
                    ? null
                    : () => onAction(visible[i]),
              ),
              if (i != visible.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ],
    );
  }

  String _weekdayInsight(List<double> averages) {
    if (averages.isEmpty) return 'Spending rhythm not enough to read yet.';
    var maxIdx = 0;
    var maxVal = averages[0];
    var minIdx = 0;
    var minVal = averages[0];
    for (var i = 1; i < averages.length; i++) {
      if (averages[i] > maxVal) {
        maxVal = averages[i];
        maxIdx = i;
      }
      if (averages[i] > 0 && (minVal <= 0 || averages[i] < minVal)) {
        minVal = averages[i];
        minIdx = i;
      }
    }
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (maxVal <= 0) {
      return 'Not enough data to read a weekday pattern yet.';
    }
    if (maxIdx >= 5) {
      return 'Weekends carry the heaviest spend — most days out land on '
          '${names[maxIdx]}.';
    }
    return 'Mid-week spend peaks on ${names[maxIdx]}, lightest on '
        '${names[minIdx]}.';
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, this.onTap});

  final FinancialInsight insight;
  final VoidCallback? onTap;

  Color get _tint {
    switch (insight.tone) {
      case InsightTone.positive:
        return AppColors.success;
      case InsightTone.warning:
        return AppColors.warning;
      case InsightTone.danger:
        return AppColors.danger;
      case InsightTone.neutral:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _tint.withAlpha(28),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(insight.icon, color: _tint, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (insight.actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: _tint,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      insight.actionLabel!,
                      style: AppTextStyles.label.copyWith(
                        color: _tint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
