import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/transaction_draft.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../utils/recurring_management.dart';
import '../../utils/subscription_catalog.dart';
import '../../utils/upcoming_payments.dart';
import '../common/subscription_badge.dart';

/// Single row in the upcoming-payments timeline.
///
/// Layout (left → right):
///   ▢ kind icon (subscription / EMI / bill)
///   ┌ payment name (primary)
///   │ linked account · billing frequency (secondary)
///   └ Auto Pay / Reminder badge (only when applicable)
///                                          amount (primary)
///                                          due-in label (secondary)
class UpcomingPaymentTile extends StatelessWidget {
  const UpcomingPaymentTile({
    super.key,
    required this.item,
    required this.onTap,
    this.trailingMenu,
  });

  final UpcomingPaymentItem item;
  final VoidCallback onTap;

  /// Optional trailing widget — typically a popup-menu icon — appended next
  /// to the amount column so users can reach Snooze / Pause without swiping.
  final Widget? trailingMenu;

  Color get _accent {
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
    switch (item.kind) {
      case RecurringKind.subscription:
        return Icons.subscriptions_rounded;
      case RecurringKind.emi:
        return Icons.receipt_long_rounded;
      case RecurringKind.other:
        final cat = item.transaction.category;
        if (cat != null) return CategoryCatalog.instance.iconForName(cat);
        return Icons.autorenew_rounded;
    }
  }

  String get _subtitle {
    final freq = item.transaction.recurrenceFrequency?.label ?? 'Recurring';
    final accountName = item.account?.name;
    if (accountName == null || accountName.isEmpty) return freq;
    return '$accountName • $freq';
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final dueLabel = upcomingDueLabel(item.daysUntil);
    final modeLabel = item.isAutoDeduct ? 'Auto Pay' : 'Reminder';
    final modeColor =
        item.isAutoDeduct ? AppColors.success : AppColors.textSecondary;

    return Material(
      color: AppColors.surface,
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
              if (_subscription != null)
                SubscriptionBadge(entry: _subscription!, size: 38)
              else
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _accent, size: 18),
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
                    const SizedBox(height: 4),
                    _ModeBadge(label: modeLabel, color: modeColor),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(item.transaction.amount),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: item.daysUntil <= 0
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (trailingMenu != null) ...[
                const SizedBox(width: 4),
                trailingMenu!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
