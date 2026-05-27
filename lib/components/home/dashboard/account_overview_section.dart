import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/design_tokens.dart';
import '../../../models/account.dart';
import '../../../models/expense.dart';
import '../../../models/transaction.dart';
import '../../../services/currency_settings.dart';
import '../../../utils/dashboard_aggregations.dart';
import 'dashboard_section_header.dart';

/// Horizontal strip of money sources: bank balances, credit card usage,
/// cash, wallets.
class AccountOverviewSection extends StatelessWidget {
  const AccountOverviewSection({
    super.key,
    required this.accounts,
    required this.transactions,
    required this.onTapAccount,
    required this.onManage,
  });

  final List<Account> accounts;
  final List<Transaction> transactions;
  final void Function(Account account) onTapAccount;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Accounts',
          subtitle: accounts.isEmpty
              ? 'Add accounts to see balances here'
              : null,
          actionLabel: accounts.isEmpty ? null : 'Manage',
          onActionTap: accounts.isEmpty ? null : onManage,
        ),
        const SizedBox(height: AppSpacing.md),
        if (accounts.isEmpty)
          _EmptyAccounts(onManage: onManage)
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return SizedBox(
                  width: 200,
                  child: _AccountCard(
                    account: account,
                    transactions: transactions,
                    onTap: () => onTapAccount(account),
                  ),
                );
              },
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemCount: accounts.length,
            ),
          ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.transactions,
    required this.onTap,
  });

  final Account account;
  final List<Transaction> transactions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (account.isCreditCard) {
      return _CreditCardCard(
        account: account,
        transactions: transactions,
        onTap: onTap,
      );
    }
    return _CashLikeCard(
      account: account,
      transactions: transactions,
      onTap: onTap,
    );
  }
}

class _CashLikeCard extends StatelessWidget {
  const _CashLikeCard({
    required this.account,
    required this.transactions,
    required this.onTap,
  });

  final Account account;
  final List<Transaction> transactions;
  final VoidCallback onTap;

  IconData get _icon {
    switch (account.type) {
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.other:
        return Icons.account_balance_wallet_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance =
        DashboardAggregations.accountBalance(account, transactions);
    final currency = CurrencySettings.instance;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(28),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(_icon, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      account.type.label,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.formatCompact(balance),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: balance < 0
                          ? AppColors.danger
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditCardCard extends StatelessWidget {
  const _CreditCardCard({
    required this.account,
    required this.transactions,
    required this.onTap,
  });

  final Account account;
  final List<Transaction> transactions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final used = DashboardAggregations.creditCardUsed(account, transactions);
    final limit = account.creditLimit;
    final ratio = limit == null || limit <= 0
        ? 0.0
        : (used / limit).clamp(0.0, 1.0);
    final color = ratio >= 0.85
        ? AppColors.danger
        : ratio >= 0.6
            ? AppColors.warning
            : AppColors.secondary;
    final currency = CurrencySettings.instance;
    final dueLabel = _formatDueLabel(account.dueDay);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withAlpha(32),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (limit != null && limit > 0) ...[
                Text(
                  '${currency.formatCompact(used)} of ${currency.formatCompact(limit)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 4,
                    backgroundColor: AppColors.background,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currency.formatCompact(limit - used)} available',
                  style: AppTextStyles.caption,
                ),
              ] else ...[
                Text(
                  currency.formatCompact(used),
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'used this month',
                  style: AppTextStyles.caption,
                ),
              ],
              if (dueLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  dueLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _formatDueLabel(int? dueDay) {
    if (dueDay == null) return null;
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, dueDay);
    if (due.isBefore(DateTime(now.year, now.month, now.day))) {
      due = DateTime(now.year, now.month + 1, dueDay);
    }
    return 'Due ${DateFormat('d MMM').format(due)}';
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Add a bank, card, or cash wallet to track balances.',
              style: AppTextStyles.caption,
            ),
          ),
          TextButton(onPressed: onManage, child: const Text('Manage')),
        ],
      ),
    );
  }
}
