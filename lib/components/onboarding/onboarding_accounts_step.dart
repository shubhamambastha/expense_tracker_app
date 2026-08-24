import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart' show AccountType, AccountTypeLabel;
import 'onboarding_step_scaffold.dart';

/// Step 4/6 — bank accounts, cards, and wallets, added before income and
/// recurring so those steps have a real account to attach to instead of
/// silently defaulting to none. Optional, repeatable (add as many as you
/// like), same `showAddAccountDialog` used everywhere else in the app.
class OnboardingAccountsStep extends StatelessWidget {
  const OnboardingAccountsStep({
    super.key,
    required this.accounts,
    required this.onAddAccount,
    required this.onSkip,
    required this.onNext,
    this.onBack,
  });

  final List<Account> accounts;
  final VoidCallback onAddAccount;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  static const _icons = {
    AccountType.bank: Icons.account_balance_rounded,
    AccountType.creditCard: Icons.credit_card_rounded,
    AccountType.cash: Icons.payments_rounded,
    AccountType.other: Icons.account_balance_wallet_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      heading: 'Add your accounts',
      subtext: 'Bank accounts, cards, cash — add as many as you like.',
      onSkip: onSkip,
      onBack: onBack,
      onNext: onNext,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final account in accounts) ...[
            _AccountRow(icon: _icons[account.type]!, account: account),
            const SizedBox(height: AppSpacing.sm),
          ],
          _AddAccountRow(onTap: onAddAccount),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.account});

  final IconData icon;
  final Account account;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(account.name, style: AppTextStyles.bodyLarge),
            ),
            Text(
              account.type.label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountRow extends StatelessWidget {
  const _AddAccountRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.cardRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Add account',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
