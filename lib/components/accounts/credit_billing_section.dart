import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../utils/account_management.dart';
import '../transaction/detail/widgets/detail_section_card.dart';

/// Billing cycle information for credit cards.
class CreditBillingSection extends StatelessWidget {
  const CreditBillingSection({
    super.key,
    required this.account,
    required this.accounts,
    required this.transactions,
  });

  final Account account;
  final List<Account> accounts;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final billing = AccountManagement.billingLabels(account);
    final linked = AccountManagement.linkedAccount(account, accounts);

    return DetailSectionCard(
      title: 'Billing',
      child: Column(
        children: [
          if (billing.statementLabel != null)
            _Row(label: 'Billing cycle', value: billing.statementLabel!),
          if (billing.dueLabel != null)
            _Row(label: 'Due date', value: billing.dueLabel!),
          if (billing.nextStatementLabel != null)
            _Row(
              label: 'Next statement',
              value: billing.nextStatementLabel!,
            ),
          if (linked != null)
            _Row(label: 'Linked bank', value: linked.displayName),
          if (billing.statementLabel == null &&
              billing.dueLabel == null &&
              linked == null)
            Text(
              'Add billing dates when editing this card.',
              style: AppTextStyles.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
