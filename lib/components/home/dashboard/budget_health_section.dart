import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import '../../../models/category_budget.dart';
import '../../../models/transaction.dart';
import '../../../services/category_catalog.dart';
import '../../../services/currency_settings.dart';
import '../../../utils/category_style.dart';
import '../../../utils/dashboard_aggregations.dart';
import 'budget_edit_sheet.dart';
import 'dashboard_section_header.dart';

const int kBudgetHealthVisibleLimit = 4;

/// "Are you overspending?" — per-category month-to-date progress.
class BudgetHealthSection extends StatelessWidget {
  const BudgetHealthSection({
    super.key,
    required this.budgets,
    required this.transactions,
  });

  final List<CategoryBudget> budgets;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final visible = budgets.take(kBudgetHealthVisibleLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Budget Health',
          subtitle: budgets.isEmpty
              ? 'Track a category to see progress here'
              : null,
          actionLabel: budgets.isEmpty ? null : '+ Add',
          onActionTap: budgets.isEmpty ? null : () => showBudgetEditSheet(context),
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          _EmptyBudgets(onAdd: () => showBudgetEditSheet(context))
        else
          Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                _BudgetCard(
                  budget: visible[i],
                  spent: DashboardAggregations.categoryMonthSpend(
                    transactions,
                    visible[i].categoryName,
                  ),
                  onTap: () => showBudgetEditSheet(
                    context,
                    initial: visible[i],
                  ),
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

class _BudgetStatus {
  const _BudgetStatus(this.label, this.color);
  final String label;
  final Color color;

  static _BudgetStatus from(double ratio) {
    if (ratio >= 1.0) return const _BudgetStatus('Overspent', AppColors.danger);
    if (ratio >= 0.85) {
      return const _BudgetStatus('Nearing limit', AppColors.warning);
    }
    return const _BudgetStatus('Healthy', AppColors.success);
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.spent,
    required this.onTap,
  });

  final CategoryBudget budget;
  final double spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio =
        budget.monthlyLimit <= 0 ? 0.0 : (spent / budget.monthlyLimit);
    final clamped = ratio.clamp(0.0, 1.0);
    final status = _BudgetStatus.from(ratio);
    final currency = CurrencySettings.instance;
    final remaining = (budget.monthlyLimit - spent).clamp(
      -budget.monthlyLimit,
      budget.monthlyLimit,
    );
    final catalog = CategoryCatalog.instance;
    final color = catalog.colorForName(budget.categoryName);
    final icon = catalog.findByName(budget.categoryName) == null
        ? CategoryIcons.iconForKey(null)
        : catalog.iconForName(budget.categoryName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Container(
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
                    child: Text(
                      budget.categoryName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusChip(label: status.label, color: status.color),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: clamped,
                  minHeight: 5,
                  backgroundColor: AppColors.background,
                  color: status.color,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${currency.formatCompact(spent)} of ${currency.formatCompact(budget.monthlyLimit)}',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  Text(
                    remaining >= 0
                        ? '${currency.formatCompact(remaining)} left'
                        : '${currency.formatCompact(-remaining)} over',
                    style: AppTextStyles.caption.copyWith(
                      color: remaining >= 0
                          ? AppColors.textSecondary
                          : AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.donut_small_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No category budgets yet',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Set monthly caps on Food, Shopping, Travel — wherever you want guardrails.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Track a category'),
          ),
        ],
      ),
    );
  }
}
