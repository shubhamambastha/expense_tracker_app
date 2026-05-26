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

/// Compact transaction row — category avatar, merchant/subtitle, amount/date.
class TransactionListItem extends StatefulWidget {
  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.account,
    this.transferToAccount,
    this.isLargeAmount = false,
    this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.onLongPress,
  });

  final Transaction transaction;
  final Account? account;
  final Account? transferToAccount;
  final bool isLargeAmount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  @override
  State<TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<TransactionListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swipeCtrl;
  static const _revealWidth = 108.0;

  @override
  void initState() {
    super.initState();
    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _swipeCtrl.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _swipeCtrl.value = (_swipeCtrl.value - details.delta.dx / _revealWidth)
        .clamp(0.0, 1.0);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    const snapDuration = Duration(milliseconds: 140);
    final velocity = details.primaryVelocity ?? 0;
    final open = _swipeCtrl.value > 0.35 ||
        (velocity < -200 && _swipeCtrl.value > 0.08);
    final close = _swipeCtrl.value < 0.65 && velocity > 200;

    if (open && !close) {
      _swipeCtrl.animateTo(1.0, duration: snapDuration, curve: Curves.easeOut);
    } else {
      _swipeCtrl.animateTo(0.0, duration: snapDuration, curve: Curves.easeOut);
    }
  }

  void _closeSwipe() {
    if (_swipeCtrl.value > 0) {
      _swipeCtrl.animateTo(0.0, duration: const Duration(milliseconds: 140));
    }
  }

  void _handleTap() {
    if (_swipeCtrl.value > 0) {
      _closeSwipe();
      return;
    }
    widget.onTap?.call();
  }

  Transaction get _tx => widget.transaction;

  Color get _categoryColor {
    final cat = _tx.category;
    if (_tx.isIncome && cat != null) {
      return IncomeCategoryCatalog.instance.colorForName(cat);
    }
    if (cat != null) {
      return CategoryCatalog.instance.colorForName(cat);
    }
    if (_tx.isTransfer) return AppColors.secondary;
    return AppColors.primary;
  }

  IconData get _leadingIcon {
    if (_tx.isTransfer) return Icons.swap_horiz_rounded;
    final cat = _tx.category;
    if (cat != null && !_tx.isIncome) {
      return CategoryCatalog.instance.iconForName(cat);
    }
    if (_tx.isIncome && cat != null) {
      return IncomeCategoryCatalog.instance.iconForName(cat);
    }
    return _tx.isIncome
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;
  }

  String get _title {
    if (_tx.isTransfer) {
      final from = widget.account?.name ?? 'Unknown';
      final to = widget.transferToAccount?.name ?? 'Unknown';
      return '$from → $to';
    }
    return _tx.counterpartyName;
  }

  String get _subtitle {
    if (_tx.isTransfer) {
      return _tx.category ?? 'Transfer';
    }
    final accountName = widget.account?.name ?? 'Unknown';
    final category = _tx.category ?? _tx.kind.label;
    if (_tx.isIncome) return '$category • $accountName';
    return '$category • $accountName';
  }

  String get _amountLabel {
    final formatted = CurrencySettings.instance.format(_tx.amount);
    if (_tx.isIncome) return '+$formatted';
    if (_tx.isTransfer) return formatted;
    return '-$formatted';
  }

  bool get _showRecurringBadge =>
      _tx.isRecurring ||
      displayTypeForTransaction(_tx) == TransactionDisplayType.subscription ||
      displayTypeForTransaction(_tx) == TransactionDisplayType.emi;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat.jm().format(_tx.date);
    final dateLabel = DateFormat.MMMd().format(_tx.date);
    final isToday = _isToday(_tx.date);

    return AnimatedBuilder(
      animation: _swipeCtrl,
      builder: (context, _) {
        final progress = _swipeCtrl.value;
        final slideLeft = _revealWidth * progress;

        return Material(
          color: AppColors.surface,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _SwipeAction(
                        icon: Icons.edit_rounded,
                        bg: AppColors.secondary.withAlpha(40),
                        fg: AppColors.secondary,
                        onTap: () {
                          _closeSwipe();
                          widget.onEdit?.call();
                        },
                      ),
                      const SizedBox(width: 4),
                      _SwipeAction(
                        icon: Icons.copy_rounded,
                        bg: AppColors.primary.withAlpha(40),
                        fg: AppColors.primary,
                        onTap: () {
                          _closeSwipe();
                          widget.onDuplicate?.call();
                        },
                      ),
                      const SizedBox(width: 4),
                      _SwipeAction(
                        icon: Icons.delete_rounded,
                        bg: AppColors.danger.withAlpha(40),
                        fg: AppColors.danger,
                        onTap: () {
                          _closeSwipe();
                          widget.onDelete?.call();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(-slideLeft, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  onTap: _handleTap,
                  onLongPress: widget.onLongPress,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: widget.isLargeAmount
                          ? Border(
                              left: BorderSide(
                                color: AppColors.warning.withAlpha(140),
                                width: 3,
                              ),
                            )
                          : _tx.isTransfer
                              ? Border(
                                  left: BorderSide(
                                    color: AppColors.secondary.withAlpha(120),
                                    width: 3,
                                  ),
                                )
                              : null,
                    ),
                    child: InkWell(
                      onTap: _handleTap,
                      onLongPress: widget.onLongPress,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CategoryAvatar(
                              color: _categoryColor,
                              icon: _leadingIcon,
                              showRecurring: _showRecurringBadge,
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
                                  const SizedBox(height: 3),
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
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: _tx.isIncome
                                        ? AppColors.success
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isToday ? timeLabel : dateLabel,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({
    required this.color,
    required this.icon,
    required this.showRecurring,
  });

  final Color color;
  final IconData icon;
  final bool showRecurring;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(32),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        if (showRecurring)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.autorenew_rounded,
                size: 10,
                color: AppColors.secondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
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
