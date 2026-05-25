import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';

/// Horizontal swipeable account chips.
///
/// Bank, credit card, cash, wallet and UPI-linked accounts all render through
/// the same chip so the user only needs to learn one tap target.
/// Optional balance preview is wired through [balancePreview] so the screen
/// can stay decoupled from a balance service.
class AccountChipsSelector extends StatelessWidget {
  const AccountChipsSelector({
    super.key,
    required this.accounts,
    required this.selectedAccountId,
    required this.onChanged,
    this.balancePreview,
    this.onAddAccount,
    this.heading = 'From account',
  });

  final List<Account> accounts;
  final int? selectedAccountId;
  final ValueChanged<Account> onChanged;
  final String? Function(Account account)? balancePreview;
  final VoidCallback? onAddAccount;
  final String heading;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return _EmptyState(onAddAccount: onAddAccount);
    }

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: accounts.length + (onAddAccount != null ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == accounts.length) {
            return _AddAccountChip(onTap: onAddAccount!);
          }
          final account = accounts[index];
          final isSelected = account.id == selectedAccountId;
          return _AccountChip(
            account: account,
            selected: isSelected,
            balancePreview: balancePreview?.call(account),
            onTap: () => onChanged(account),
          );
        },
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    required this.account,
    required this.selected,
    required this.onTap,
    this.balancePreview,
  });

  final Account account;
  final bool selected;
  final VoidCallback onTap;
  final String? balancePreview;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.chipRadius,
      child: AnimatedContainer(
        duration: AppDurations.micro,
        curve: AppCurves.spring,
        constraints: const BoxConstraints(minWidth: 132, maxWidth: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(32)
              : AppColors.surfaceSecondary,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(
            color: selected
                ? AppColors.primary.withAlpha(140)
                : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withAlpha(selected ? 48 : 28),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                _iconFor(account.type),
                color: accent,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    balancePreview ?? account.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.other:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

class _AddAccountChip extends StatelessWidget {
  const _AddAccountChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.chipRadius,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onAddAccount});

  final VoidCallback? onAddAccount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Add an account to assign this transaction.',
                style: AppTextStyles.caption,
              ),
            ),
            if (onAddAccount != null)
              TextButton(
                onPressed: onAddAccount,
                child: const Text('Add'),
              ),
          ],
        ),
      ),
    );
  }
}
