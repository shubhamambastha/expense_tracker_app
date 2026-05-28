import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../models/transaction.dart';
import '../../services/currency_settings.dart';
import '../../utils/account_management.dart';
import '../../utils/dashboard_aggregations.dart';
import 'bank_account_card.dart';

/// Wallet or cash account list card.
class WalletAccountCard extends StatelessWidget {
  const WalletAccountCard({
    super.key,
    required this.account,
    required this.transactions,
    required this.accounts,
    required this.onTap,
  });

  final Account account;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final balance =
        DashboardAggregations.accountBalance(account, transactions);
    final linked = AccountManagement.linkedAccount(account, accounts);
    final isDefault = AccountManagement.isDefaultAccount(account.id);
    final typeLabel = AccountManagement.typeLabel(account);

    return AccountCardShell(
      onTap: onTap,
      icon: AccountManagement.iconForAccount(account),
      iconTone: account.type == AccountType.cash
          ? AppColors.success
          : AppColors.secondary,
      title: account.displayName,
      subtitle: account.providerLabel ?? typeLabel,
      trailing: Text(
        currency.formatCompact(balance),
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
      ),
      badges: [
        if (isDefault) const AccountDefaultBadge(),
      ],
      footer: [
        if (linked != null)
          Text(
            'Linked to ${linked.displayName}',
            style: AppTextStyles.caption,
          ),
      ],
    );
  }
}
