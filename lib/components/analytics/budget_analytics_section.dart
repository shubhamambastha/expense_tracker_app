import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/category_budget.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../home/dashboard/dashboard_section_header.dart';
import 'widgets/analytics_section_card.dart';

/// Reusable "budget vs spend" row.
///
/// Mirrors the dashboard's Budget Health card visually but is purpose-built
/// for analytics: it prioritises usage percentage and surfaces a smart state
/// ("Healthy / Near Limit / Exceeded") next to the amount.
class BudgetAnalyticsSection extends StatelessWidget {
  const BudgetAnalyticsSection({
    super.key,
    required this.budgets,
    required this.spendByCategory,
    required this.onOpenBudgetSettings,
  });

  final List<CategoryBudget> budgets;
  final Map<String, double> spendByCategory;
  final VoidCallback onOpenBudgetSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Budget Analytics',
          subtitle: budgets.isEmpty
              ? 'Set budgets to track guardrails here.'
              : 'Current cycle progress for each cap.',
          actionLabel: budgets.isEmpty ? 'Set up' : 'Manage',
          onActionTap: onOpenBudgetSettings,
        ),
        const SizedBox(height: AppSpacing.md),
        if (budgets.isEmpty)
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
                  child: Icon(
                    Icons.donut_small_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'You haven\'t set any budgets yet. Add a cap to surface usage and remaining headroom here.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          AnalyticsSectionCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                for (var i = 0; i < budgets.length; i++) ...[
                  _BudgetAnalyticsRow(
                    budget: budgets[i],
                    spent: spendByCategory[budgets[i].categoryName] ?? 0,
                  ),
                  if (i != budgets.length - 1)
                    Divider(
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

class _BudgetState {
  const _BudgetState(this.label, this.color);
  final String label;
  final Color color;

  static _BudgetState from(double ratio) {
    if (ratio >= 1.0) return _BudgetState('Exceeded', AppColors.danger);
    if (ratio >= 0.85) {
      return _BudgetState('Near limit', AppColors.warning);
    }
    return _BudgetState('Healthy', AppColors.success);
  }
}

class _BudgetAnalyticsRow extends StatelessWidget {
  const _BudgetAnalyticsRow({
    required this.budget,
    required this.spent,
  });

  final CategoryBudget budget;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final ratio = budget.monthlyLimit <= 0 ? 0.0 : spent / budget.monthlyLimit;
    final clamped = ratio.clamp(0.0, 1.0);
    final state = _BudgetState.from(ratio);
    final pct = (ratio * 100).clamp(0, 999).round();
    final remaining = budget.monthlyLimit - spent;
    final currency = CurrencySettings.instance;
    final color = CategoryCatalog.instance.colorForName(budget.categoryName);
    final icon = CategoryCatalog.instance.iconForName(budget.categoryName);

    return Padding(
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
                      budget.categoryName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currency.formatCompact(spent)} of '
                      '${currency.formatCompact(budget.monthlyLimit)}',
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: state.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: state.color.withAlpha(28),
                      borderRadius: AppRadii.pillRadius,
                    ),
                    child: Text(
                      state.label,
                      style: AppTextStyles.label.copyWith(
                        color: state.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 5,
              backgroundColor: AppColors.background,
              color: state.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining >= 0
                ? '${currency.formatCompact(remaining)} left this cycle'
                : '${currency.formatCompact(-remaining)} over the cap',
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: remaining >= 0
                  ? AppColors.textSecondary
                  : AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
