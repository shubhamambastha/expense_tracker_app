import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import '../../../models/category_budget.dart';
import '../../../services/category_budget_service.dart';
import '../../../services/category_catalog.dart';
import '../../../services/currency_settings.dart';
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
