import 'package:flutter/material.dart';

import '../../../../config/design_tokens.dart';
import '../transaction_detail_view_data.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_section_card.dart';

class AccountPaymentSection extends StatelessWidget {
  const AccountPaymentSection({super.key, required this.data});

  final TransactionDetailViewData data;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      title: 'Account & Payment',
      child: Column(
        children: [
          if (data.tx.isTransfer) ...[
            DetailInfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'From account',
              value: data.account?.name ?? 'Unknown account',
            ),
            DetailInfoRow(
              icon: Icons.arrow_forward_rounded,
              label: 'To account',
              value: data.transferToAccount?.name ?? 'Unknown account',
            ),
          ] else if (data.tx.isIncome) ...[
            DetailInfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Deposit account',
              value: data.account?.name ?? 'Unknown account',
            ),
            if (data.accountTypeLabel != null)
              DetailInfoRow(
                icon: Icons.credit_card_outlined,
                label: 'Account type',
                value: data.accountTypeLabel!,
              ),
          ] else ...[
            DetailInfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payment account',
              value: data.account?.name ?? 'Unknown account',
            ),
            if (data.accountTypeLabel != null)
              DetailInfoRow(
                icon: Icons.credit_card_outlined,
                label: 'Linked account',
                valueWidget: _AccountTypeChip(label: data.accountTypeLabel!),
              ),
          ],
        ],
      ),
    );
  }
}

class _AccountTypeChip extends StatelessWidget {
  const _AccountTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTextStyles.bodyMedium.color,
          ),
        ),
      ),
    );
  }
}
