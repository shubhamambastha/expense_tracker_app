import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/design_tokens.dart';
import '../../../services/currency_settings.dart';

/// Gradient "Total Balance" card with this-month Income/Spent sub-stats.
class HeroOverviewCard extends StatelessWidget {
  const HeroOverviewCard({
    super.key,
    required this.totalBalance,
    required this.monthIncome,
    required this.monthSpent,
  });

  final double totalBalance;
  final double monthIncome;
  final double monthSpent;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: AppRadii.cardRadius,
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withAlpha(191),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
                currency.format(totalBalance),
                style: AppTextStyles.displayMedium.copyWith(
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
              .animate()
              .fadeIn(duration: AppDurations.reveal)
              .slideY(
                begin: 0.08,
                end: 0,
                duration: AppDurations.reveal,
                curve: AppCurves.spring,
              ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _StatBadge(
                icon: Icons.arrow_outward_rounded,
                label: 'Income',
                value: currency.formatCompact(monthIncome),
              ),
              const SizedBox(width: AppSpacing.xl),
              _StatBadge(
                icon: Icons.call_received_rounded,
                label: 'Spent',
                value: currency.formatCompact(monthSpent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: Colors.white.withAlpha(178),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
