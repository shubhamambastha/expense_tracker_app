import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/expense.dart';
import 'profile_manage_card.dart';

/// Profile entry for payment accounts (compact; list in See all sheet).
class AccountsSettingsSection extends StatelessWidget {
  const AccountsSettingsSection({
    super.key,
    required this.accounts,
    required this.onAddAccount,
  });

  final List<Account> accounts;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final count = accounts.length;
    final subtitle = count == 0
        ? 'No accounts yet'
        : count == 1
            ? '1 account'
            : '$count accounts';

    return ProfileManageCard(
      title: 'Accounts',
      subtitle: subtitle,
      seeAllLabel: 'See all',
      addLabel: 'Add',
      onSeeAll: () => _openAllAccountsSheet(context),
      onAdd: onAddAccount,
    );
  }

  Future<void> _openAllAccountsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;

        return SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    'All accounts',
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: accounts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No accounts yet. Tap Add to create bank, card, or cash accounts.',
                              textAlign: TextAlign.center,
                              style: Theme.of(sheetContext).textTheme.bodyMedium,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];
                            return ListTile(
                              leading: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Theme.of(sheetContext).colorScheme.primary,
                              ),
                              title: Text(
                                account.name,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(account.type.label),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
