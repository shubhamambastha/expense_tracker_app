import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../transaction/detail/widgets/detail_section_card.dart';

enum CreditCardAction { edit, payBill, addEmi, archive }

/// Action rows for credit card detail screen.
class CreditCardActionsSection extends StatelessWidget {
  const CreditCardActionsSection({
    super.key,
    required this.onAction,
  });

  final void Function(CreditCardAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      title: 'Card actions',
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.edit_rounded,
            label: 'Edit card',
            onTap: () => onAction(CreditCardAction.edit),
          ),
          _ActionRow(
            icon: Icons.payment_rounded,
            label: 'Pay credit bill',
            onTap: () => onAction(CreditCardAction.payBill),
          ),
          _ActionRow(
            icon: Icons.receipt_long_rounded,
            label: 'Add EMI',
            onTap: () => onAction(CreditCardAction.addEmi),
          ),
          _ActionRow(
            icon: Icons.archive_rounded,
            label: 'Archive card',
            tone: AppColors.warning,
            onTap: () => onAction(CreditCardAction.archive),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: color),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
