import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
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
                  child: Text(
                    'All accounts',
                    style: AppTextStyles.headingSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: accounts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(
                              'No accounts yet. Tap Add to create bank, card, or cash accounts.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          itemCount: accounts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final account = accounts[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: AppColors.border),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(28),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons
                                        .account_balance_wallet_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  account.name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  account.type.label,
                                  style: AppTextStyles.caption,
                                ),
                              ),
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
