import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../models/transaction_draft.dart';
import '../../models/transaction_filters.dart';
import '../../utils/transaction_subtype_helpers.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../services/income_category_catalog.dart';

Future<void> showTransactionDetailSheet({
  required BuildContext context,
  required Transaction transaction,
  required Account? account,
  Account? transferToAccount,
  VoidCallback? onEdit,
  VoidCallback? onDuplicate,
  VoidCallback? onDelete,
}) {
  final displayType = displayTypeForTransaction(transaction);
  final categoryColor = _colorFor(transaction);

  String amountLabel;
  switch (transaction.kind) {
    case TransactionKind.income:
      amountLabel = '+${CurrencySettings.instance.format(transaction.amount)}';
    case TransactionKind.transfer:
      amountLabel = CurrencySettings.instance.format(transaction.amount);
    case TransactionKind.expense:
      amountLabel = '-${CurrencySettings.instance.format(transaction.amount)}';
  }

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryColor.withAlpha(32),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _iconFor(transaction),
                      color: categoryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.isTransfer
                              ? '${account?.name ?? '?'} → ${transferToAccount?.name ?? '?'}'
                              : transaction.counterpartyName,
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayType.label,
                          style: AppTextStyles.caption.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(amountLabel, style: AppTextStyles.headingSmall),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (transaction.category != null)
                _DetailTile(
                  icon: Icons.label_outline_rounded,
                  label: 'Category',
                  value: transaction.category!,
                ),
              if (transaction.isTransfer) ...[
                _DetailTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'From',
                  value: account?.name ?? 'Unknown account',
                ),
                _DetailTile(
                  icon: Icons.arrow_forward_rounded,
                  label: 'To',
                  value: transferToAccount?.name ?? 'Unknown account',
                ),
              ] else
                _DetailTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: transaction.isIncome ? 'Deposit to' : 'Account',
                  value: account?.name ?? 'Unknown account',
                ),
              _DetailTile(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: DateFormat.yMMMd().add_jm().format(transaction.date),
              ),
              if (transaction.note != null && transaction.note!.isNotEmpty)
                _DetailTile(
                  icon: Icons.notes_rounded,
                  label: 'Note',
                  value: transaction.note!,
                ),
              if (transaction.isRecurring)
                _DetailTile(
                  icon: Icons.autorenew_rounded,
                  label: 'Recurring',
                  value: 'Yes',
                ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        onEdit?.call();
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        onDuplicate?.call();
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Duplicate'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onDelete?.call();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: const Icon(Icons.delete_rounded, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Color _colorFor(Transaction transaction) {
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

IconData _iconFor(Transaction transaction) {
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

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.caption),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
