import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/recurring_event.dart';
import '../../models/transaction.dart';
import '../../services/currency_settings.dart';
import '../../utils/account_management.dart';
import '../../utils/recurring_management.dart';
import '../transaction/detail/widgets/detail_section_card.dart';

/// Active EMIs charged to a credit card.
class CreditEmiSection extends StatelessWidget {
  const CreditEmiSection({
    super.key,
    required this.account,
    required this.transactions,
    required this.events,
    required this.accounts,
    this.onManageEmi,
  });

  final Account account;
  final List<Transaction> transactions;
  final List<RecurringEvent> events;
  final List<Account> accounts;
  final VoidCallback? onManageEmi;

  @override
  Widget build(BuildContext context) {
    final emis = AccountManagement.emisForCard(
      account,
      transactions,
      events,
      accounts,
    );
    final currency = CurrencySettings.instance;

    return DetailSectionCard(
      title: 'EMIs',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (emis.isEmpty)
            Text(
              'No active EMIs on this card.',
              style: AppTextStyles.bodySmall,
            )
          else
            ...emis.map((item) {
              final progress =
                  RecurringManagement.emiProgress(item.transaction);
              final remainingMonths = progress?.remainingMonths ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
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
                          Text(
                            '$remainingMonths months · '
                            '${currency.formatCompact(item.monthlyEquivalent)}/mo',
                            style: AppTextStyles.caption,
                          ),
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
              );
            }),
          if (onManageEmi != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onManageEmi,
                child: const Text('Manage EMI'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
