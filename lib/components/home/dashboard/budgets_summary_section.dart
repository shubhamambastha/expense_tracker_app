import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import '../../../models/category_budget.dart';
import '../../../services/category_catalog.dart';
import 'dashboard_section_header.dart';

const int kHomeBudgetsLimit = 4;

/// Compact "current cycle" budget progress card for the home screen.
class BudgetsSummarySection extends StatelessWidget {
  const BudgetsSummarySection({
    super.key,
    required this.budgets,
    required this.spendByCategory,
    required this.onSeeAll,
  });

  final List<CategoryBudget> budgets;
  final Map<String, double> spendByCategory;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final items = budgets.take(kHomeBudgetsLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Budgets',
          actionLabel: items.isEmpty ? null : 'See all',
          onActionTap: items.isEmpty ? null : onSeeAll,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          _EmptyBudgets(onTap: onSeeAll)
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _BudgetHomeRow(
                      budget: items[i],
                      spent: spendByCategory[items[i].categoryName] ?? 0,
                    ),
                    if (i != items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.border,
                        indent: 40,
                      ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BudgetHomeRow extends StatelessWidget {
  const _BudgetHomeRow({required this.budget, required this.spent});

  final CategoryBudget budget;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final ratio = budget.monthlyLimit <= 0 ? 0.0 : spent / budget.monthlyLimit;
    final clamped = ratio.clamp(0.0, 1.0);
    final stateColor = ratio >= 1.0
        ? AppColors.danger
        : ratio >= 0.85
        ? AppColors.warning
        : AppColors.success;
    final pctLabel = '${(ratio * 100).clamp(0, 999).round()}%';
    final color = CategoryCatalog.instance.colorForName(budget.categoryName);
    final icon = CategoryCatalog.instance.iconForName(budget.categoryName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withAlpha(32),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  budget.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                pctLabel,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: stateColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 5,
              backgroundColor: AppColors.background,
              color: stateColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.donut_small_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Set a budget to track spending caps here.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
