import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';
import '../../models/transaction_draft.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../utils/recurring_management.dart';
import '../../utils/subscription_catalog.dart';
import '../common/subscription_badge.dart';
import 'upcoming_timeline_section.dart';

/// Card for a single active subscription or generic recurring expense.
///
/// Used by both [ActiveSubscriptionsSection] and [RecurringExpensesSection]
/// — the shell stays identical; only the accent colour and the optional
/// payment-mode chip change.
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAction,
    this.accentColor,
    this.fallbackIcon,
    this.showPaymentModeChip = false,
  });

  final RecurringScheduleItem item;
  final VoidCallback onTap;
  final void Function(RecurringQuickAction action) onAction;

  /// Override the icon-badge accent. Defaults to a kind-aware tone.
  final Color? accentColor;
  final IconData? fallbackIcon;

  /// Recurring Expenses surface a "Auto Deduct / Reminder Only" chip in the
  /// header; Subscriptions show a tighter "Auto Pay" badge instead.
  final bool showPaymentModeChip;

  Color get _accent {
    if (accentColor != null) return accentColor!;
    switch (item.kind) {
      case RecurringKind.subscription:
        return AppColors.secondary;
      case RecurringKind.emi:
        return AppColors.warning;
      case RecurringKind.other:
        return AppColors.primary;
    }
  }

  SubscriptionEntry? get _subscription =>
      SubscriptionCatalog.forName(item.transaction.counterpartyName);

  IconData get _icon {
    final cat = item.transaction.category;
    if (item.kind == RecurringKind.subscription) {
      return Icons.subscriptions_rounded;
    }
    if (item.kind == RecurringKind.emi) {
      return Icons.receipt_long_rounded;
    }
    if (cat != null) {
      return CategoryCatalog.instance.iconForName(cat);
    }
    return fallbackIcon ?? Icons.autorenew_rounded;
  }

  String? get _renewalLabel {
    final next = item.nextDueDate;
    if (next == null) return null;
    return DateFormat.MMMd().format(next);
  }

  bool get _isOverdue {
    final next = item.nextDueDate;
    if (next == null) return false;
    final today = DateTime.now();
    return next.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final frequency =
        item.transaction.recurrenceFrequency?.label ?? 'Recurring';
    final renewal = _renewalLabel;
    final paused = item.isPaused;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(
              color: paused
                  ? AppColors.border
                  : _accent.withAlpha(60),
              width: paused ? 1 : 1.1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_subscription != null)
                    SubscriptionBadge(entry: _subscription!, size: 40)
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _accent.withAlpha(paused ? 24 : 36),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon, color: _accent, size: 20),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.transaction.counterpartyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currency.format(item.transaction.amount)} · '
                          '$frequency',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  _CardOverflowMenu(
                    onSelect: onAction,
                    isPaused: paused,
                    kind: item.kind,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _MetaRow(
                      icon: Icons.account_balance_wallet_rounded,
                      label: item.account?.name ?? 'No account linked',
                    ),
                  ),
                  if (renewal != null)
                    _MetaRow(
                      icon: Icons.event_rounded,
                      label: paused ? 'Paused' : 'Renews $renewal',
                      tone: paused ? AppColors.textSecondary : AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (showPaymentModeChip)
                    _StatusChip(
                      label: item.isAutoDeduct ? 'Auto Deduct' : 'Reminder Only',
                      color: item.isAutoDeduct
                          ? AppColors.success
                          : AppColors.textSecondary,
                    )
                  else if (item.isAutoDeduct)
                    const _StatusChip(
                      label: 'Auto Pay',
                      color: AppColors.success,
                    ),
                  if (paused)
                    _StatusChip(
                      label: 'Paused',
                      color: AppColors.textSecondary,
                    )
                  else if (_isOverdue)
                    const _StatusChip(
                      label: 'Overdue',
                      color: AppColors.danger,
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    this.tone,
  });

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: tone ?? AppColors.textSecondary,
              fontWeight: tone != null ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CardOverflowMenu extends StatelessWidget {
  const _CardOverflowMenu({
    required this.onSelect,
    required this.isPaused,
    required this.kind,
  });

  final void Function(RecurringQuickAction action) onSelect;
  final bool isPaused;
  final RecurringKind kind;

  /// Kind-aware copy for the close action. Subscriptions get the cancellation
  /// language users already think in; recurring expenses fall back to a
  /// neutral verb because "cancel" doesn't apply to e.g. rent or utilities.
  ({IconData icon, String label}) get _closeMeta {
    switch (kind) {
      case RecurringKind.subscription:
        return (icon: Icons.cancel_rounded, label: 'Cancel subscription');
      case RecurringKind.emi:
        // EMI is handled by EmiCard's own menu, but keep a sensible fallback
        // in case SubscriptionCard is reused for an EMI-flavoured item.
        return (icon: Icons.task_alt_rounded, label: 'Mark as completed');
      case RecurringKind.other:
        return (icon: Icons.archive_rounded, label: 'Close schedule');
    }
  }

  @override
  Widget build(BuildContext context) {
    final close = _closeMeta;
    return PopupMenuButton<RecurringQuickAction>(
      tooltip: 'More actions',
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
      color: AppColors.surfaceSecondary,
      onSelected: onSelect,
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: RecurringQuickAction.markPaid,
          child: _CardMenuRow(
            icon: Icons.check_circle_rounded,
            label: 'Mark paid',
          ),
        ),
        const PopupMenuItem(
          value: RecurringQuickAction.snooze,
          child: _CardMenuRow(
            icon: Icons.snooze_rounded,
            label: 'Snooze 3 days',
          ),
        ),
        PopupMenuItem(
          value: RecurringQuickAction.pause,
          child: _CardMenuRow(
            icon: isPaused
                ? Icons.play_circle_rounded
                : Icons.pause_circle_rounded,
            label: isPaused ? 'Resume schedule' : 'Pause schedule',
          ),
        ),
        PopupMenuItem(
          value: RecurringQuickAction.close,
          child: _CardMenuRow(
            icon: close.icon,
            label: close.label,
            tone: AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _CardMenuRow extends StatelessWidget {
  const _CardMenuRow({required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;

  /// Optional override colour — used to surface destructive actions (close
  /// schedule) with the same `AppColors.danger` accent the delete-transaction
  /// dialog uses elsewhere.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
