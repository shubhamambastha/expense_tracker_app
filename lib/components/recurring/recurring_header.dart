import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/recurring_management.dart';
import '../../utils/upcoming_payments.dart';

/// Compact header for the Recurring Payments Manager.
///
/// Renders the screen title, the current calendar-month context line, and a
/// four-tile metrics strip:
/// monthly total · active subscriptions · EMIs remaining · next payment label.
///
/// Tiles intentionally mirror `_SummaryTile` from the analytics
/// `SubscriptionsSection` so the two surfaces feel like one family.
class RecurringHeader extends StatelessWidget {
  const RecurringHeader({
    super.key,
    required this.snapshot,
    required this.monthLabel,
  });

  final RecurringManagementSnapshot snapshot;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final nextLabel = snapshot.nextUpcoming == null
        ? 'No upcoming'
        : upcomingDueLabel(snapshot.nextUpcoming!.daysUntil);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recurring & EMI', style: AppTextStyles.headingMedium),
        const SizedBox(height: 2),
        Text(
          '$monthLabel · ${currency.formatCompact(snapshot.totalMonthly)} '
          'recurring this month',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'This month',
                value: currency.formatCompact(snapshot.totalMonthly),
                icon: Icons.event_repeat_rounded,
                tone: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                label: 'Subscriptions',
                value: _countLabel(snapshot.subscriptions.length, 'active'),
                icon: Icons.subscriptions_rounded,
                tone: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                label: 'EMIs',
                value: _countLabel(snapshot.emis.length, 'open'),
                icon: Icons.receipt_long_rounded,
                tone: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                label: 'Next payment',
                value: nextLabel,
                icon: Icons.schedule_rounded,
                tone: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _countLabel(int count, String suffix) {
    if (count == 0) return 'None';
    return '$count $suffix';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: tone.withAlpha(32),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 12, color: tone),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
