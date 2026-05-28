import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../services/currency_settings.dart';
import '../transaction/detail/widgets/detail_section_card.dart';

/// Compact transaction preview for account detail screens.
class AccountTransactionsPreview extends StatelessWidget {
  const AccountTransactionsPreview({
    super.key,
    required this.account,
    required this.transactions,
    this.onViewAll,
    this.onTapTransaction,
  });

  final Account account;
  final List<Transaction> transactions;
  final VoidCallback? onViewAll;
  final void Function(Transaction transaction)? onTapTransaction;

  @override
  Widget build(BuildContext context) {
    final filtered = transactions
        .where(
          (t) =>
              t.accountId == account.id ||
              t.transferToAccountId == account.id,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final preview = filtered.take(5).toList();
    final currency = CurrencySettings.instance;

    return DetailSectionCard(
      title: 'Recent transactions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (preview.isEmpty)
            Text(
              'No transactions on this account yet.',
              style: AppTextStyles.bodySmall,
            )
          else
            ...preview.map(
              (tx) => _TxRow(
                transaction: tx,
                currency: currency,
                onTap: onTapTransaction == null
                    ? null
                    : () => onTapTransaction!(tx),
              ),
            ),
          if (onViewAll != null && filtered.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onViewAll,
                child: const Text('View all transactions'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.transaction,
    required this.currency,
    this.onTap,
  });

  final Transaction transaction;
  final dynamic currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final amountColor = isExpense ? AppColors.danger : AppColors.success;
    final prefix = isExpense ? '−' : '+';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.counterpartyName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormat('d MMM').format(transaction.date),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Text(
              '$prefix${currency.format(transaction.amount)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
