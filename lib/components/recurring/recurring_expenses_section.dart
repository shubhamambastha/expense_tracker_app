import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/recurring_management.dart';
import '../common/states/empty_state.dart';
import '../common/states/state_icon_badge.dart';
import '../home/dashboard/dashboard_section_header.dart';
import 'subscription_card.dart';
import 'upcoming_timeline_section.dart';

/// "Other" recurring expenses — anything flagged recurring but not classified
/// as a subscription or EMI: rent, electricity, internet, insurance, SIP
/// reminders, etc.
///
/// Reuses [SubscriptionCard] with a primary accent and the Auto-Deduct /
/// Reminder-Only payment-mode chip enabled.
class RecurringExpensesSection extends StatelessWidget {
  const RecurringExpensesSection({
    super.key,
    required this.items,
    required this.monthlyTotal,
    required this.onTapItem,
    required this.onAction,
    required this.onAddRecurringExpense,
  });

  final List<RecurringScheduleItem> items;
  final double monthlyTotal;
  final void Function(RecurringScheduleItem item) onTapItem;
  final void Function(
    RecurringQuickAction action,
    RecurringScheduleItem item,
  ) onAction;
  final VoidCallback onAddRecurringExpense;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Recurring Expenses',
          subtitle: items.isEmpty
              ? null
              : '${items.length} active · ${currency.formatCompact(monthlyTotal)} '
                  'per month',
          actionLabel: items.isEmpty ? null : 'Add',
          onActionTap: items.isEmpty ? null : onAddRecurringExpense,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          EmptyState(
            title: 'No other recurring expenses',
            subtitle:
                'Track rent, internet, electricity, insurance or SIP reminders '
                'to see them in your monthly plan.',
            icon: Icons.autorenew_rounded,
            iconTone: StateBadgeTone.primary,
            layout: EmptyStateLayout.compact,
            primaryActionLabel: 'Add Recurring Expense',
            primaryActionIcon: Icons.add_rounded,
            onPrimaryAction: onAddRecurringExpense,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                SubscriptionCard(
                  item: items[i],
                  accentColor: AppColors.primary,
                  showPaymentModeChip: true,
                  onTap: () => onTapItem(items[i]),
                  onAction: (action) => onAction(action, items[i]),
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
