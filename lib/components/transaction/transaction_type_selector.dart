import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../config/feature_flags.dart';
import '../../models/transaction_draft.dart';

/// Segmented control for transaction kind (expense · income · optional transfer).
///
/// The selected segment is the *only* coloured element so the eye is pulled
/// to it instantly — important because category suggestions reshuffle off
/// this choice. Default selection is [TransactionKind.expense].
class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.includeTransfer = false,
  });

  final TransactionKind selected;
  final ValueChanged<TransactionKind> onChanged;
  final bool includeTransfer;

  List<TransactionKind> get _kinds {
    if (includeTransfer) return TransactionKind.values;
    return FeatureFlags.selectableTransactionKinds;
  }

  @override
  Widget build(BuildContext context) {
    final kinds = _kinds;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.buttonRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < kinds.length; i++) ...[
            Expanded(
              child: _Segment(
                icon: _iconFor(kinds[i]),
                label: kinds[i].label,
                selected: selected == kinds[i],
                onTap: () => onChanged(kinds[i]),
              ),
            ),
            if (i != kinds.length - 1) const SizedBox(width: 4),
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
