import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../models/expense.dart';

/// Compact accordion-style expense ledger row.
/// Swipe left slightly to reveal small Edit / Delete icons on the right.
class ExpenseListItem extends StatefulWidget {
  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.categoryColor,
    required this.account,
    this.onEdit,
    this.onDelete,
  });

  final Expense expense;
  final Color categoryColor;
  final Account? account;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<ExpenseListItem> createState() => _ExpenseListItemState();
}

class _ExpenseListItemState extends State<ExpenseListItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _swipeCtrl;

  /// How far the row slides left when fully open (two compact icon slots).
  static const _revealWidth = 72.0;

  @override
  void initState() {
    super.initState();
    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _swipeCtrl.dispose();
    super.dispose();
  }

  void _handleEdit() => widget.onEdit?.call();
  void _handleDelete() => widget.onDelete?.call();

  IconData _iconForType(ExpenseType type) {
    switch (type) {
      case ExpenseType.oneTime:   return Icons.event_available_rounded;
      case ExpenseType.recurring: return Icons.autorenew_rounded;
    }
  }

  IconData _iconForAccount(AccountType? type) {
    switch (type) {
      case AccountType.bank:      return Icons.account_balance_rounded;
      case AccountType.creditCard: return Icons.credit_card_rounded;
      case AccountType.cash:      return Icons.payments_rounded;
      case AccountType.other:
      case null:                  return Icons.account_balance_wallet_rounded;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Swipe left (negative dx) opens actions on the right.
    _swipeCtrl.value = (_swipeCtrl.value - details.delta.dx / _revealWidth)
        .clamp(0.0, 1.0);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    const snapCurve = Curves.easeOut;
    const snapDuration = Duration(milliseconds: 140);
    final velocity = details.primaryVelocity ?? 0;
    final open = _swipeCtrl.value > 0.35 ||
        (velocity < -200 && _swipeCtrl.value > 0.08);
    final close = _swipeCtrl.value < 0.65 && velocity > 200;

    if (open && !close) {
      _swipeCtrl.animateTo(1.0, duration: snapDuration, curve: snapCurve);
    } else {
      _swipeCtrl.animateTo(0.0, duration: snapDuration, curve: snapCurve);
    }
  }

  void _onRowTap() {
    if (_swipeCtrl.value > 0) {
      _swipeCtrl.animateTo(0.0, duration: const Duration(milliseconds: 140));
      return;
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final expense = widget.expense;

    return AnimatedBuilder(
      animation: _swipeCtrl,
      builder: (context, _) {
        final progress = _swipeCtrl.value;
        final slideLeft = _revealWidth * progress;

        return Material(
          color: cs.surface,
          elevation: 0,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: _revealWidth,
                child: Opacity(
                  opacity: progress,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(
                          icon: Icons.edit_rounded,
                          bg: cs.secondaryContainer,
                          fg: cs.onSecondaryContainer,
                          onTap: _handleEdit,
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.delete_rounded,
                          bg: cs.errorContainer,
                          fg: cs.onErrorContainer,
                          onTap: _handleDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(-slideLeft, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  onTap: _onRowTap,
                  child: Material(
                    color: cs.surface,
                    child: InkWell(
                      onTap: _onRowTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    CategoryCatalog.instance
                                    .iconForName(expense.category),
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
                                Flexible(
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      CurrencySettings.instance
                                          .format(expense.amount),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
/// Compact swipe action — small icon-only control.
// ──────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: fg, size: 16),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
/// Expanded details panel
// ──────────────────────────────────────────────────────────────────────────────
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
  final IconData Function(ExpenseType) iconForType;
  final IconData Function(AccountType?) iconForAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(75),
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
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.yMMMd().format(expense.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
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
            color: expense.isRecurring ? cs.tertiary : cs.primary,
          ),
          _DetailRow(
            icon: iconForAccount(account?.type),
            label: account?.type.label ?? 'Other',
            color: cs.primary,
          ),
          _DetailRow(
            icon: Icons.account_balance_wallet_rounded,
            label: account?.name ?? 'Unknown account',
            color: cs.secondary,
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
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
