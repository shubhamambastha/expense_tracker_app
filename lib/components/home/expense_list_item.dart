import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../models/expense.dart';

/// Compact accordion-style expense ledger row.
class ExpenseListItem extends StatefulWidget {
  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.categoryColor,
    required this.account,
  });

  final Expense expense;
  final Color categoryColor;
  final Account? account;

  @override
  State<ExpenseListItem> createState() => _ExpenseListItemState();
}

class _ExpenseListItemState extends State<ExpenseListItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final expense = widget.expense;

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.categoryColor.withAlpha(28),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        _iconForCategory(expense.category),
                        color: widget.categoryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        expense.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      NumberFormat.simpleCurrency().format(expense.amount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 10),
                  _ExpenseDetails(
                    expense: expense,
                    account: widget.account,
                    categoryColor: widget.categoryColor,
                    iconForCategory: _iconForCategory,
                    iconForType: _iconForType,
                    iconForAccount: _iconForAccount,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Bills':
        return Icons.receipt_rounded;
      case 'Health':
        return Icons.favorite_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  IconData _iconForType(ExpenseType type) {
    switch (type) {
      case ExpenseType.oneTime:
        return Icons.event_available_rounded;
      case ExpenseType.recurring:
        return Icons.autorenew_rounded;
    }
  }

  IconData _iconForAccount(AccountType? accountType) {
    switch (accountType) {
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.other:
      case null:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

class _ExpenseDetails extends StatelessWidget {
  const _ExpenseDetails({
    required this.expense,
    required this.account,
    required this.categoryColor,
    required this.iconForCategory,
    required this.iconForType,
    required this.iconForAccount,
  });

  final Expense expense;
  final Account? account;
  final Color categoryColor;
  final IconData Function(String category) iconForCategory;
  final IconData Function(ExpenseType type) iconForType;
  final IconData Function(AccountType? type) iconForAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(expense.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: iconForType(expense.type),
            label: expense.type.label,
            color: expense.isRecurring
                ? colorScheme.tertiary
                : colorScheme.primary,
          ),
          _DetailRow(
            icon: iconForAccount(account?.type),
            label: account?.type.label ?? 'Other',
            color: colorScheme.primary,
          ),
          _DetailRow(
            icon: Icons.account_balance_wallet_rounded,
            label: account?.name ?? 'Unknown account',
            color: colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(7),
            ),
            padding: const EdgeInsets.all(3),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
