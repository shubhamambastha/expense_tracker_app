import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/transaction_draft.dart';

/// Two-way segmented control: Expense · Income.
///
/// The selected segment is the *only* coloured element so the eye is pulled
/// to it instantly — important because category suggestions reshuffle off
/// this choice. Default selection is [TransactionKind.expense].
class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TransactionKind selected;
  final ValueChanged<TransactionKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.buttonRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final kind in TransactionKind.values) ...[
            Expanded(
              child: _Segment(
                icon: _iconFor(kind),
                label: kind.label,
                selected: selected == kind,
                onTap: () => onChanged(kind),
              ),
            ),
            if (kind != TransactionKind.values.last)
              const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(TransactionKind kind) {
    switch (kind) {
      case TransactionKind.expense:
        return Icons.south_west_rounded;
      case TransactionKind.income:
        return Icons.north_east_rounded;
      case TransactionKind.transfer:
        return Icons.swap_horiz_rounded;
    }
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: AppDurations.micro,
        curve: AppCurves.spring,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(32)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: fg,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
