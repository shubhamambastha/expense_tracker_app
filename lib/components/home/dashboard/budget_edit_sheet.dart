import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import '../../../models/category_budget.dart';
import '../../../services/category_budget_service.dart';
import '../../../services/category_catalog.dart';
import '../../../services/currency_settings.dart';
import '../../../services/settings_preferences.dart';
import '../../../utils/snackbar_helper.dart';
import '../../transaction/category_pills_selector.dart';

/// Bottom sheet for creating or updating a per-category monthly budget.
///
/// Reused by the dashboard Budget Health section header and by long-pressing
/// a budget card.
Future<void> showBudgetEditSheet(
  BuildContext context, {
  CategoryBudget? initial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => _BudgetEditSheet(initial: initial),
  );
}

class _BudgetEditSheet extends StatefulWidget {
  const _BudgetEditSheet({this.initial});

  final CategoryBudget? initial;

  @override
  State<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends State<_BudgetEditSheet> {
  late final TextEditingController _amountController;
  String? _categoryName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoryName = widget.initial?.categoryName;
    _amountController = TextEditingController(
      text: widget.initial?.monthlyLimit.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final cat = _categoryName;
    if (cat == null || cat.trim().isEmpty) {
      SnackbarHelper.showMessage(context, 'Pick a category');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      SnackbarHelper.showMessage(context, 'Enter a positive amount');
      return;
    }
    setState(() => _saving = true);
    try {
      await CategoryBudgetService.instance.upsert(
        categoryName: cat,
        monthlyLimit: amount,
        currencyCode: CurrencySettings.instance.currencyCode,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackbarHelper.showSuccess(context, 'Budget saved for $cat');
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showMessage(context, 'Could not save budget: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.initial;
    if (existing == null) return;
    setState(() => _saving = true);
    try {
      await CategoryBudgetService.instance.remove(existing);
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackbarHelper.showSuccess(context, 'Budget removed');
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showMessage(context, 'Could not remove budget: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final currency = CurrencySettings.instance;
    final isEditing = widget.initial != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing ? 'Update budget' : 'Track a category',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick a category and set the monthly amount you\'re comfortable spending.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListenableBuilder(
              listenable: CategoryCatalog.instance,
              builder: (context, _) {
                return CategoryPillsSelector(
                  selectedName: _categoryName,
                  onChanged: (name) =>
                      setState(() => _categoryName = name),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _amountController,
                    autofocus: !isEditing,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      prefixText: currency.inputPrefix,
                      labelText: 'Monthly limit',
                      hintText: '0',
                    ),
                  ),
                  _LiveAllocation(
                    amountController: _amountController,
                    categoryName: _categoryName,
                    currency: currency,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (isEditing) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : _delete,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.danger.withAlpha(120),
                              ),
                              foregroundColor: AppColors.danger,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Remove'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(isEditing ? 'Update' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Running total of all category budgets — including the amount being typed —
/// against the overall monthly limit. Hidden when no limit is set.
class _LiveAllocation extends StatelessWidget {
  const _LiveAllocation({
    required this.amountController,
    required this.categoryName,
    required this.currency,
  });

  final TextEditingController amountController;
  final String? categoryName;
  final CurrencySettings currency;

  @override
  Widget build(BuildContext context) {
    final limit = SettingsPreferences.instance.monthlySpendingLimit;
    if (limit == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: amountController,
      builder: (context, _) {
        // upsert is keyed by category, so the selected category's existing
        // budget gets replaced by the typed amount rather than added to it.
        final others = CategoryBudgetService.instance.budgets
            .where((b) => b.categoryName != categoryName)
            .fold<double>(0, (sum, b) => sum + b.monthlyLimit);
        final typed = double.tryParse(amountController.text.trim()) ?? 0;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Semantics(
            liveRegion: true,
            child: BudgetAllocationNote(
              limit: limit,
              allocated: others + typed,
              currency: currency,
            ),
          ),
        );
      },
    );
  }
}

/// Shows how category budgets add up against the monthly limit, and what
/// that means when they don't (under- or over-allocated).
class BudgetAllocationNote extends StatelessWidget {
  const BudgetAllocationNote({
    super.key,
    required this.limit,
    required this.allocated,
    required this.currency,
  });

  final double limit;
  final double allocated;
  final CurrencySettings currency;

  @override
  Widget build(BuildContext context) {
    final diff = allocated - limit;
    final balanced = diff.abs() < 0.5;
    final over = diff > 0;
    final color = balanced
        ? AppColors.success
        : over
        ? AppColors.warning
        : AppColors.primary;
    final icon = balanced
        ? Icons.check_circle_rounded
        : over
        ? Icons.warning_amber_rounded
        : Icons.info_outline_rounded;
    final headline = balanced
        ? 'Fully allocated'
        : over
        ? 'Over-allocated by ${currency.format(diff)}'
        : '${currency.format(-diff)} unallocated';
    final detail = balanced
        ? 'Category budgets add up to your ${currency.format(limit)} limit.'
        : over
        ? 'Category budgets total ${currency.format(allocated)} against a '
              '${currency.format(limit)} limit, so you\'ll hit the monthly '
              'limit before every category cap is used.'
        : '${currency.format(allocated)} of ${currency.format(limit)} is '
              'split by category. Spending outside those categories still '
              'counts toward the monthly limit.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
