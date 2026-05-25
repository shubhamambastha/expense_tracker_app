import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';
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
    final expense = widget.expense;

    return AnimatedBuilder(
      animation: _swipeCtrl,
      builder: (context, _) {
        final progress = _swipeCtrl.value;
        final slideLeft = _revealWidth * progress;

        return Material(
          color: AppColors.surface,
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
                          bg: AppColors.secondary.withAlpha(40),
                          fg: AppColors.secondary,
                          onTap: _handleEdit,
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.delete_rounded,
                          bg: AppColors.danger.withAlpha(40),
                          fg: AppColors.danger,
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
                    color: AppColors.surface,
                    child: InkWell(
                      onTap: _onRowTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: widget.categoryColor.withAlpha(32),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    CategoryCatalog.instance
                                        .iconForName(expense.category),
                                    color: widget.categoryColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    expense.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Flexible(
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      CurrencySettings.instance
                                          .format(expense.amount),
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AnimatedSize(
                              duration: AppDurations.short,
                              curve: AppCurves.spring,
                              child: _isExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.md,
                                      ),
                                      child: _ExpenseDetails(
                                        expense: expense,
                                        account: widget.account,
                                        categoryColor: widget.categoryColor,
                                        iconForType: _iconForType,
                                        iconForAccount: _iconForAccount,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category,
                      style: AppTextStyles.label.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.yMMMd().format(expense.date),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: iconForType(expense.type),
            label: expense.type.label,
            color: expense.isRecurring
                ? AppColors.secondary
                : AppColors.primary,
          ),
          _DetailRow(
            icon: iconForAccount(account?.type),
            label: account?.type.label ?? 'Other',
            color: AppColors.primary,
          ),
          _DetailRow(
            icon: Icons.account_balance_wallet_rounded,
            label: account?.name ?? 'Unknown account',
            color: AppColors.secondary,
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(3),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
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
