import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/design_tokens.dart';
import '../../../services/category_catalog.dart';
import '../../../services/currency_settings.dart';
import '../../../utils/upcoming_payments.dart';
import 'dashboard_section_header.dart';

const int kUpcomingPaymentsVisibleLimit = 4;

/// Recurring transactions whose next due date is approaching — bills, EMI,
/// subscriptions, salaries.
class UpcomingPaymentsSection extends StatelessWidget {
  const UpcomingPaymentsSection({
    super.key,
    required this.payments,
    required this.onTap,
    required this.onViewAll,
  });

  final List<UpcomingPayment> payments;
  final void Function(UpcomingPayment payment) onTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final items = payments.take(kUpcomingPaymentsVisibleLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Upcoming Payments',
          subtitle: items.isEmpty
              ? 'Nothing due in the next 30 days'
              : null,
          actionLabel: items.isEmpty ? null : 'All',
          onActionTap: items.isEmpty ? null : onViewAll,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          const _EmptyUpcoming()
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _UpcomingCard(
                  payment: items[i],
                  onTap: () => onTap(items[i]),
                ),
                if (i != items.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.payment, required this.onTap});

  final UpcomingPayment payment;
  final VoidCallback onTap;

  Color get _accentColor {
    if (payment.daysUntil <= 1) return AppColors.warning;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final tx = payment.transaction;
    final currency = CurrencySettings.instance;
    final categoryColor = tx.category == null
        ? AppColors.secondary
        : CategoryCatalog.instance.colorForName(tx.category!);
    final icon = tx.category == null
        ? Icons.event_repeat_rounded
        : CategoryCatalog.instance.iconForName(tx.category!);
    final dueLabel = upcomingDueLabel(payment.daysUntil);
    final dayLabel = DateFormat('d MMM').format(payment.dueDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: categoryColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _DueChip(label: dueLabel, color: _accentColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            payment.account?.name ?? dayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(tx.amount),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (payment.isAutoDeduct) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.autorenew_rounded,
                          size: 11,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Auto',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
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

class _EmptyUpcoming extends StatelessWidget {
  const _EmptyUpcoming();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No bills coming up',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mark a transaction as recurring to track its due dates here.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
