import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../utils/transaction_subtype_helpers.dart';

/// Quick-pick chips for expense subtypes that map to filter types
/// (EMI, Subscription) via category + recurring defaults.
class ExpenseSubtypeChips extends StatelessWidget {
  const ExpenseSubtypeChips({
    super.key,
    required this.selectedCategory,
    required this.onSubtypeSelected,
  });

  final String? selectedCategory;
  final ValueChanged<String> onSubtypeSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: TransactionSubtypeHelpers.expenseSubtypes.map((label) {
          final selected = selectedCategory == label;
          return FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onSubtypeSelected(label),
          );
        }).toList(),
      ),
    );
  }
}

/// Quick Refund chip for the income flow.
class IncomeRefundChip extends StatelessWidget {
  const IncomeRefundChip({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  final String? selectedCategory;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = TransactionSubtypeHelpers.isRefundCategory(
      selectedCategory,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilterChip(
          label: const Text('Refund'),
          selected: selected,
          onSelected: (_) => onSelected(),
        ),
      ),
    );
  }
}
