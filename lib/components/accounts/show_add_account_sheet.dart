import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/expense.dart';

/// Account type picked from the FAB menu on the accounts list screen.
enum AddAccountChoice { bank, creditCard, wallet, cash }

/// FAB menu: Add Bank / Credit Card / Wallet / Cash.
Future<AddAccountChoice?> showAddAccountSheet(BuildContext context) {
  return showModalBottomSheet<AddAccountChoice>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Account', style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose where your money lives or moves from.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              _AddRow(
                icon: Icons.account_balance_rounded,
                tone: AppColors.primary,
                title: 'Add Bank Account',
                subtitle: 'Savings, salary, or current account.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(AddAccountChoice.bank),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AddRow(
                icon: Icons.credit_card_rounded,
                tone: AppColors.warning,
                title: 'Add Credit Card',
                subtitle: 'Track limit, usage, and due dates.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(AddAccountChoice.creditCard),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AddRow(
                icon: Icons.account_balance_wallet_rounded,
                tone: AppColors.secondary,
                title: 'Add Wallet',
                subtitle: 'GPay, PhonePe, Paytm, Amazon Pay, UPI.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(AddAccountChoice.wallet),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AddRow(
                icon: Icons.payments_rounded,
                tone: AppColors.success,
                title: 'Add Cash Wallet',
                subtitle: 'Physical cash on hand.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(AddAccountChoice.cash),
              ),
            ],
          ),
        ),
      );
    },
  );
}

AccountType accountTypeForChoice(AddAccountChoice choice) {
  switch (choice) {
    case AddAccountChoice.bank:
      return AccountType.bank;
    case AddAccountChoice.creditCard:
      return AccountType.creditCard;
    case AddAccountChoice.wallet:
      return AccountType.other;
    case AddAccountChoice.cash:
      return AccountType.cash;
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: tone.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tone.withAlpha(36),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: tone, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
