import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/design_tokens.dart';
import '../../../services/currency_settings.dart';

/// Card headed by today's balance; income and expenses sit beneath.
class HeroOverviewCard extends StatelessWidget {
  const HeroOverviewCard({
    super.key,
    required this.todayBalance,
    required this.todayIncome,
    required this.todayExpenses,
  });

  final double todayBalance;
  final double todayIncome;
  final double todayExpenses;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final balanceColor = _balanceColor(todayBalance);

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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    "Today's balance",
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: _emphasizedBalance(
                    Text(
                      currency.format(todayBalance),
                      textAlign: TextAlign.end,
                      style: AppTextStyles.displayMedium.copyWith(
                        height: 1.05,
                        color: balanceColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TodayMetricTile(
                  label: 'Income',
                  value: currency.format(todayIncome),
                  valueColor: AppColors.success,
                  labelIcon: Icons.trending_up_rounded,
                  tone: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TodayMetricTile(
                  label: 'Expenses',
                  value: currency.format(todayExpenses),
                  valueColor: AppColors.textPrimary,
                  labelIcon: Icons.trending_down_rounded,
                  tone: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emphasizedBalance(Widget child) {
    return child
        .animate()
        .fadeIn(duration: AppDurations.reveal)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppDurations.reveal,
          curve: AppCurves.spring,
        );
  }

  static Color _balanceColor(double balance) {
    if (balance > 0) return AppColors.success;
    if (balance < 0) return AppColors.danger;
    return AppColors.textPrimary;
  }
}

class _TodayMetricTile extends StatelessWidget {
  const _TodayMetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.labelIcon,
    required this.tone,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData labelIcon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(labelIcon, size: 18, color: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headingLarge.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
