import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/recurring_event.dart';
import '../../models/transaction.dart';
import '../../utils/account_management.dart';
import '../transaction/detail/widgets/detail_section_card.dart';

/// Linked payment sources and recurring charges for an account.
class AccountLinkedSourcesSection extends StatelessWidget {
  const AccountLinkedSourcesSection({
    super.key,
    required this.account,
    required this.accounts,
    required this.transactions,
    this.events = const [],
  });

  final Account account;
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<RecurringEvent> events;

  @override
  Widget build(BuildContext context) {
    final linked = AccountManagement.linkedAccount(account, accounts);
    final subscriptions = AccountManagement.linkedSubscriptions(
      account,
      transactions,
      events,
      accounts,
    );

    final items = <String>[];
    if (account.isWallet && account.walletProvider != null) {
      items.add('${account.walletProvider!.label} wallet');
    }
    if (linked != null) {
      items.add('Linked to ${linked.displayName}');
    }
    for (final sub in subscriptions.take(4)) {
      items.add('${sub.transaction.counterpartyName} subscription');
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return DetailSectionCard(
      title: 'Linked sources',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items
            .map(
              (label) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      _iconFor(label),
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(label, style: AppTextStyles.bodyMedium),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  IconData _iconFor(String label) {
    if (label.contains('subscription')) {
      return Icons.subscriptions_rounded;
    }
    if (label.contains('Linked')) return Icons.link_rounded;
    return Icons.account_balance_wallet_rounded;
  }
}
