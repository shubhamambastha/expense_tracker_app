import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/design_tokens.dart';
import '../../../models/account.dart';
import '../../../models/transaction.dart';
import '../../../models/transaction_draft.dart';
import '../../../services/category_catalog.dart';
import '../../../services/currency_settings.dart';
import '../../../services/income_category_catalog.dart';
import 'dashboard_section_header.dart';

const int kRecentTransactionsLimit = 5;

/// Compact list of the latest transactions on the home screen.
class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.onTap,
    required this.onViewAll,
  });

  final List<Transaction> transactions;
  final List<Account> accounts;
  final void Function(Transaction tx) onTap;
  final VoidCallback onViewAll;

  List<Transaction> get _recent {
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(kRecentTransactionsLimit).toList();
  }

  Account? _accountFor(int? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final items = _recent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Recent Transactions',
          actionLabel: items.isEmpty ? null : 'View All',
          onActionTap: items.isEmpty ? null : onViewAll,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isNotEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _RecentTransactionTile(
                    transaction: items[i],
                    account: _accountFor(items[i].accountId),
                    transferToAccount:
                        _accountFor(items[i].transferToAccountId),
                    onTap: () => onTap(items[i]),
                  ),
                  if (i != items.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                      indent: AppSpacing.lg,
                      endIndent: AppSpacing.lg,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({
    required this.transaction,
    required this.account,
    required this.transferToAccount,
    required this.onTap,
  });

  final Transaction transaction;
  final Account? account;
  final Account? transferToAccount;
  final VoidCallback onTap;

  Color get _categoryColor {
    final cat = transaction.category;
    if (transaction.isIncome && cat != null) {
      return IncomeCategoryCatalog.instance.colorForName(cat);
    }
    if (cat != null) {
      return CategoryCatalog.instance.colorForName(cat);
    }
    if (transaction.isTransfer) return AppColors.secondary;
    return AppColors.primary;
  }

  IconData get _icon {
    if (transaction.isTransfer) return Icons.swap_horiz_rounded;
    final cat = transaction.category;
    if (cat != null && transaction.isExpense) {
      return CategoryCatalog.instance.iconForName(cat);
    }
    if (cat != null && transaction.isIncome) {
      return IncomeCategoryCatalog.instance.iconForName(cat);
    }
    return transaction.isIncome
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;
  }

  String get _title {
    if (transaction.isTransfer) {
      final from = account?.name ?? 'Unknown';
      final to = transferToAccount?.name ?? 'Unknown';
      return '$from → $to';
    }
    return transaction.counterpartyName;
  }

  String get _subtitle {
    final category = transaction.category ?? transaction.kind.label;
    final accountName = account?.name;
    if (accountName == null || accountName.isEmpty) return category;
    return '$category • $accountName';
  }

  String get _amountLabel {
    final formatted = CurrencySettings.instance.format(transaction.amount);
    if (transaction.isIncome) return '+$formatted';
    if (transaction.isTransfer) return formatted;
    return '-$formatted';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _isToday(transaction.date)
        ? DateFormat.jm().format(transaction.date)
        : DateFormat.MMMd().format(transaction.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _categoryColor.withAlpha(32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: _categoryColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _amountLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: transaction.isIncome
                          ? AppColors.success
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
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

