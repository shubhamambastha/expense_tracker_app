import 'package:flutter/material.dart';

import '../../../components/dialogs/add_account_dialog.dart';
import '../../../components/profile/profile_manage_card.dart';
import '../../../components/settings/settings_picker_helpers.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../models/account.dart';
import '../../../models/expense.dart';
import '../../../utils/snackbar_helper.dart';

/// Dedicated screen for managing bank accounts, credit cards, wallets, and
/// cash. Tapping "See all" opens a per-type bottom sheet, "Add" routes to
/// the existing add-account flow.
class AccountsAndCardsPage extends StatelessWidget {
  const AccountsAndCardsPage({
    super.key,
    required this.accounts,
    required this.onAddAccount,
  });

  final List<Account> accounts;
  final OnAddAccount onAddAccount;

  @override
  Widget build(BuildContext context) {
    final bankAccounts =
        accounts.where((a) => a.type == AccountType.bank).toList();
    final creditCards =
        accounts.where((a) => a.type == AccountType.creditCard).toList();
    final cashAccounts =
        accounts.where((a) => a.type == AccountType.cash).toList();

    return SettingsSubpageScaffold(
      title: 'Accounts & Cards',
      subtitle:
          'Manage the places your money lives — link banks, cards, wallets, '
          'and cash so transactions land in the right bucket.',
      children: [
        ProfileManageCard(
          title: 'Bank Accounts',
          subtitle: _countLabel(bankAccounts.length, 'account', 'accounts'),
          seeAllLabel: 'See all',
          addLabel: 'Add Account',
          onSeeAll: () => _openAccountsSheet(
            context,
            title: 'Bank accounts',
            list: bankAccounts,
            emptyHint: 'No bank accounts yet. Tap Add Account to create one.',
          ),
          onAdd: () => onAddAccount(initialType: AccountType.bank),
        ),
        const SizedBox(height: AppSpacing.md),
        ProfileManageCard(
          title: 'Credit Cards',
          subtitle: _countLabel(creditCards.length, 'card', 'cards'),
          seeAllLabel: 'See all',
          addLabel: 'Add Card',
          onSeeAll: () => _openAccountsSheet(
            context,
            title: 'Credit cards',
            list: creditCards,
            emptyHint:
                'No credit cards yet. Tap Add Card to start tracking one.',
            extraTiles: [
              SettingsTile(
                icon: Icons.calendar_month_rounded,
                title: 'Manage EMI',
                subtitle: 'Split purchases into EMIs',
                futureReady: true,
                onTap: () => _stub(context, 'EMI manager'),
              ),
              SettingsTile(
                icon: Icons.event_repeat_rounded,
                title: 'Edit billing cycle',
                subtitle: 'Statement start & due day',
                futureReady: true,
                onTap: () => _stub(context, 'Billing cycle'),
              ),
            ],
          ),
          onAdd: () => onAddAccount(initialType: AccountType.creditCard),
        ),
        const SizedBox(height: AppSpacing.md),
        ProfileManageCard(
          title: 'Wallets & UPI',
          subtitle: 'GPay, PhonePe, Paytm',
          seeAllLabel: 'See all',
          addLabel: 'Link',
          onSeeAll: () => _stub(context, 'Wallets & UPI'),
          onAdd: () => _stub(context, 'Link wallet'),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: SettingsTile(
            icon: Icons.savings_rounded,
            title: 'Cash Wallet',
            subtitle: cashAccounts.isEmpty
                ? 'No cash wallet yet'
                : _countLabel(cashAccounts.length, 'wallet', 'wallets'),
            valueLabel: cashAccounts.isEmpty ? 'Add' : 'Manage',
            onTap: cashAccounts.isEmpty
                ? () => onAddAccount(initialType: AccountType.cash)
                : () => _openAccountsSheet(
                      context,
                      title: 'Cash wallet',
                      list: cashAccounts,
                      emptyHint: 'No cash wallet yet.',
                    ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAccountsSheet(
    BuildContext context, {
    required String title,
    required List<Account> list,
    required String emptyHint,
    List<Widget> extraTiles = const [],
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xs,
                    AppSpacing.xl,
                    AppSpacing.sm,
                  ),
                  child: Text(title, style: AppTextStyles.headingSmall),
                ),
                Expanded(
                  child: list.isEmpty && extraTiles.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(
                              emptyHint,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          children: [
                            for (final account in list) ...[
                              SettingsAccountListRow(account: account),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            if (extraTiles.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: AppRadii.cardRadius,
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    for (var i = 0;
                                        i < extraTiles.length;
                                        i++) ...[
                                      extraTiles[i],
                                      if (i != extraTiles.length - 1)
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: AppColors.border,
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _countLabel(int count, String singular, String plural) {
    if (count == 0) return 'None yet';
    if (count == 1) return '1 $singular';
    return '$count $plural';
  }

  void _stub(BuildContext context, String label) {
    SnackbarHelper.showMessage(context, '$label is coming soon');
  }
}
