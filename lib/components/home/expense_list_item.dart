import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../models/expense.dart';

/// Compact single-line expense ledger row.
class ExpenseListItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width - 52,
          ),
          child: Row(
            children: [
              Tooltip(
                message: expense.category,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: categoryColor.withAlpha(28),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    _iconForCategory(expense.category),
                    color: categoryColor,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 108,
                child: Text(
                  expense.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _InlineMeta(
                icon: _iconForType(expense.type),
                label: _shortTypeLabel(expense.type),
                tooltip: expense.type.label,
                color: expense.isRecurring
                    ? colorScheme.tertiary
                    : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              if (expense.isRecurring) ...[
                _IconOnlyMeta(
                  icon: Icons.repeat_rounded,
                  tooltip: expense.endDate == null
                      ? 'Recurring'
                      : 'Recurring until ${DateFormat.MMMd().format(expense.endDate!)}',
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
              ],
              _InlineMeta(
                icon: _iconForAccount(account?.type),
                label: account?.name ?? 'Unknown account',
                tooltip: account?.type.label ?? 'Account missing',
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                DateFormat.MMMd().format(expense.date),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
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

  String _shortTypeLabel(ExpenseType type) {
    switch (type) {
      case ExpenseType.oneTime:
        return 'Once';
      case ExpenseType.recurring:
        return 'Recur';
    }
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 92),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconOnlyMeta extends StatelessWidget {
  const _IconOnlyMeta({
    required this.icon,
    required this.tooltip,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}
