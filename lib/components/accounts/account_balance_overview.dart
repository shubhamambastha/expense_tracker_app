import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../services/currency_settings.dart';
import '../../utils/account_management.dart';
import '../../utils/dashboard_aggregations.dart';
import '../transaction/detail/widgets/detail_section_card.dart';

/// Balance overview for non-credit account detail.
class AccountBalanceOverview extends StatelessWidget {
  const AccountBalanceOverview({
    super.key,
    required this.account,
    required this.transactions,
  });

  final Account account;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final balance =
        DashboardAggregations.accountBalance(account, transactions);
    final monthSpend = AccountManagement.monthSpendForAccount(
      account,
      transactions,
    );
    final monthIncome = AccountManagement.monthIncomeForAccount(
      account,
      transactions,
    );

    return DetailSectionCard(
      title: 'Balance',
      child: Column(
        children: [
          _Row(
            label: 'Current balance',
            value: currency.format(balance),
            emphasized: true,
          ),
          _Row(
            label: 'Opening balance',
            value: currency.format(account.openingBalance),
          ),
          _Row(
            label: 'Spent this month',
            value: currency.format(monthSpend),
          ),
          _Row(
            label: 'Income this month',
            value: currency.format(monthIncome),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            value,
            style: (emphasized
                    ? AppTextStyles.headingSmall
                    : AppTextStyles.bodyMedium)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
