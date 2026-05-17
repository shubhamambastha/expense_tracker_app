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
                        expense.category,
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
    required this.iconForType,
    required this.iconForAccount,
  });

  final Expense expense;
  final Account? account;
  final Color categoryColor;
  final IconData Function(ExpenseType type) iconForType;
  final IconData Function(AccountType? type) iconForAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final endDate = expense.endDate;

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
                      expense.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat.yMMMd().format(expense.date),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DetailPill(
                icon: iconForAccount(account?.type),
                label: account?.name ?? 'Unknown account',
                color: colorScheme.primary,
              ),
              _DetailPill(
                icon: iconForType(expense.type),
                label: expense.type.label,
                color: expense.isRecurring
                    ? colorScheme.tertiary
                    : colorScheme.primary,
              ),
              if (endDate != null)
                _DetailPill(
                  icon: Icons.event_busy_rounded,
                  label: 'Ends ${DateFormat.MMMd().format(endDate)}',
                  color: colorScheme.tertiary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
