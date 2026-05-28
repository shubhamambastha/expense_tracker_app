import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../utils/account_management.dart';
import 'bank_account_card.dart';

/// Header for account detail screens.
class AccountDetailHeader extends StatelessWidget {
  const AccountDetailHeader({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final isDefault = AccountManagement.isDefaultAccount(account.id);
    final icon = AccountManagement.iconForAccount(account);
    final typeLabel = AccountManagement.typeLabel(account);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(32),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        account.displayName,
                        style: AppTextStyles.headingSmall,
                      ),
                    ),
                    if (isDefault) const AccountDefaultBadge(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  account.providerLabel != null
                      ? '${account.providerLabel} · $typeLabel'
                      : typeLabel,
                  style: AppTextStyles.bodySmall,
                ),
                if (account.name != account.displayName) ...[
                  const SizedBox(height: 2),
                  Text(account.name, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
