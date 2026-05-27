import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import '../../../utils/financial_insights.dart';
import 'dashboard_section_header.dart';

const int kFinancialInsightsVisibleLimit = 3;

/// Conversational, behavioral nudges. Stays calm — at most 3 cards at a time.
class FinancialInsightsSection extends StatelessWidget {
  const FinancialInsightsSection({
    super.key,
    required this.insights,
    required this.onAction,
  });

  final List<FinancialInsight> insights;
  final void Function(FinancialInsight insight) onAction;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    final visible = insights.take(kFinancialInsightsVisibleLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: 'Insights',
          subtitle: 'Tiny, useful nudges based on your activity.',
        ),
        const SizedBox(height: AppSpacing.md),
        Column(
          children: [
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
        ),
      ],
    );
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
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
