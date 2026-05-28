import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../utils/account_management.dart';

/// Segmented type selector for add/edit account form.
class AddAccountTypeSelector extends StatelessWidget {
  const AddAccountTypeSelector({
    super.key,
    required this.selectedType,
    required this.isWallet,
    required this.onTypeChanged,
    this.enabled = true,
  });

  final AccountType selectedType;
  final bool isWallet;
  final void Function(AccountType type, {bool wallet}) onTypeChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _Chip(
          label: 'Bank',
          selected: selectedType == AccountType.bank,
          onTap: enabled
              ? () => onTypeChanged(AccountType.bank, wallet: false)
              : null,
        ),
        _Chip(
          label: 'Credit Card',
          selected: selectedType == AccountType.creditCard,
          onTap: enabled
              ? () => onTypeChanged(AccountType.creditCard, wallet: false)
              : null,
        ),
        _Chip(
          label: 'Wallet',
          selected: selectedType == AccountType.other && isWallet,
          onTap: enabled
              ? () => onTypeChanged(AccountType.other, wallet: true)
              : null,
        ),
        _Chip(
          label: 'Cash',
          selected: selectedType == AccountType.cash,
          onTap: enabled
              ? () => onTypeChanged(AccountType.cash, wallet: false)
              : null,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
      selectedColor: AppColors.primary.withAlpha(48),
      checkmarkColor: AppColors.primary,
    );
  }
}

/// Icon preview for the selected account type.
class AccountTypeIconPreview extends StatelessWidget {
  const AccountTypeIconPreview({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(32),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          AccountManagement.iconForAccount(account),
          size: 32,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
