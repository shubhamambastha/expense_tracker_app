import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/recurring_event.dart';
import '../../models/transaction.dart';
import '../../services/currency_settings.dart';
import '../../utils/account_management.dart';
import '../transaction/detail/widgets/detail_section_card.dart';

/// Auto-pay subscriptions charged to a credit card.
class CreditAutoPaymentsSection extends StatelessWidget {
  const CreditAutoPaymentsSection({
    super.key,
    required this.account,
    required this.transactions,
    required this.events,
    required this.accounts,
  });

  final Account account;
  final List<Transaction> transactions;
  final List<RecurringEvent> events;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final subs = AccountManagement.linkedSubscriptions(
      account,
      transactions,
      events,
      accounts,
    );
    final currency = CurrencySettings.instance;

    if (subs.isEmpty) return const SizedBox.shrink();

    return DetailSectionCard(
      title: 'Linked auto payments',
      child: Column(
        children: subs
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(32),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.subscriptions_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.transaction.counterpartyName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.isAutoDeduct)
                            Text('Auto pay', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Text(
                      currency.formatCompact(item.monthlyEquivalent),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
