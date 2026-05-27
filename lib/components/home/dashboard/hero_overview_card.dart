import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/design_tokens.dart';
import '../../../services/currency_settings.dart';

/// MOST important section: today's spend + safe daily spend + monthly progress.
///
/// Keeps the surface decoration in step with `MonthlyAnalyticsCard` so the
/// dashboard feels like a single coherent system.
class HeroOverviewCard extends StatelessWidget {
  const HeroOverviewCard({
    super.key,
    required this.todaySpend,
    required this.monthSpent,
    required this.monthlyLimit,
    required this.safeDailySpend,
    required this.daysRemaining,
    this.onSetBudgetTap,
  });

  final double todaySpend;
  final double monthSpent;
  final double? monthlyLimit;
  final double? safeDailySpend;
  final int daysRemaining;
  final VoidCallback? onSetBudgetTap;

  double get _ratio {
    final limit = monthlyLimit;
    if (limit == null || limit <= 0) return 0;
    return (monthSpent / limit).clamp(0.0, 1.0);
  }

  Color get _progressColor {
    final limit = monthlyLimit;
    if (limit == null) return AppColors.primary;
    final ratio = monthSpent / limit;
    if (ratio >= 1.0) return AppColors.danger;
    if (ratio >= 0.85) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final limit = monthlyLimit;
    final safeDaily = safeDailySpend;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    Text(
                      currency.format(todaySpend),
                      style: AppTextStyles.displaySmall.copyWith(height: 1.05),
                    )
                        .animate()
                        .fadeIn(duration: AppDurations.reveal)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: AppDurations.reveal,
                          curve: AppCurves.spring,
                        ),
                    const SizedBox(height: 4),
                    Text(
                      todaySpend > 0 ? 'spent today' : 'no spending yet',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              _HeroIconBadge(
                icon: _progressColor == AppColors.danger
                    ? Icons.warning_amber_rounded
                    : Icons.account_balance_wallet_rounded,
                tint: _progressColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SafeDailyRow(
            safeDaily: safeDaily,
            daysRemaining: daysRemaining,
            limit: limit,
            onSetBudgetTap: onSetBudgetTap,
          ),
          const SizedBox(height: AppSpacing.lg),
          _BudgetProgress(
            ratio: _ratio,
            color: _progressColor,
            monthSpent: monthSpent,
            limit: limit,
          ),
        ],
      ),
    );
  }
}

class _HeroIconBadge extends StatelessWidget {
  const _HeroIconBadge({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withAlpha(48), tint.withAlpha(20)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withAlpha(60)),
      ),
      child: Icon(icon, color: tint, size: 22),
    );
  }
}

class _SafeDailyRow extends StatelessWidget {
  const _SafeDailyRow({
    required this.safeDaily,
    required this.daysRemaining,
    required this.limit,
    required this.onSetBudgetTap,
  });

  final double? safeDaily;
  final int daysRemaining;
  final double? limit;
  final VoidCallback? onSetBudgetTap;

  @override
  Widget build(BuildContext context) {
    if (limit == null) {
      return _SetBudgetCallout(onTap: onSetBudgetTap);
    }
    final currency = CurrencySettings.instance;
    final value = safeDaily ?? 0;
    final label = value <= 0
        ? 'Over your monthly limit'
        : '${currency.format(value)} safe to spend';
    final sub = value <= 0
        ? 'Consider easing off until next month.'
        : '$daysRemaining ${daysRemaining == 1 ? 'day' : 'days'} left in the month';
    final color = value <= 0 ? AppColors.danger : AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetBudgetCallout extends StatelessWidget {
  const _SetBudgetCallout({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.chipRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(22),
            borderRadius: AppRadii.chipRadius,
            border: Border.all(color: AppColors.primary.withAlpha(60)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Set a monthly budget to unlock safe daily spend',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  const _BudgetProgress({
    required this.ratio,
    required this.color,
    required this.monthSpent,
    required this.limit,
  });

  final double ratio;
  final Color color;
  final double monthSpent;
  final double? limit;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final hasLimit = limit != null;
    final label = hasLimit
        ? '${currency.formatCompact(monthSpent)} of ${currency.formatCompact(limit!)} used'
        : '${currency.formatCompact(monthSpent)} spent this month';
    final pct = hasLimit ? '${(ratio * 100).round()}%' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (pct != null)
              Text(
                pct,
                style: AppTextStyles.label.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: hasLimit ? ratio : null,
            minHeight: 6,
            backgroundColor: AppColors.background,
            color: color,
          ),
        ),
      ],
    );
  }
}
