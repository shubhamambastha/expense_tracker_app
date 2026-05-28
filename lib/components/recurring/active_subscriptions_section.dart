import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/recurring_management.dart';
import '../common/states/empty_state.dart';
import '../common/states/state_icon_badge.dart';
import '../home/dashboard/dashboard_section_header.dart';
import 'subscription_card.dart';
import 'upcoming_timeline_section.dart';

/// Lists the user's active subscriptions (Netflix, Cursor, Spotify, etc.).
///
/// Each item renders a [SubscriptionCard]. Empty inline state shown when no
/// subscriptions exist but other recurring kinds still do.
class ActiveSubscriptionsSection extends StatelessWidget {
  const ActiveSubscriptionsSection({
    super.key,
    required this.items,
    required this.monthlyTotal,
    required this.onTapItem,
    required this.onAction,
    required this.onAddSubscription,
  });

  final List<RecurringScheduleItem> items;
  final double monthlyTotal;
  final void Function(RecurringScheduleItem item) onTapItem;
  final void Function(
    RecurringQuickAction action,
    RecurringScheduleItem item,
  ) onAction;
  final VoidCallback onAddSubscription;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Active Subscriptions',
          subtitle: items.isEmpty
              ? null
              : '${items.length} active · ${currency.formatCompact(monthlyTotal)} '
                  'per month',
          actionLabel: items.isEmpty ? null : 'Add',
          onActionTap: items.isEmpty ? null : onAddSubscription,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          EmptyState(
            title: 'No subscriptions tracked',
            subtitle:
                'Add Netflix, Spotify, ChatGPT, or any other recurring service '
                'to keep an eye on the monthly burden.',
            icon: Icons.subscriptions_rounded,
            iconTone: StateBadgeTone.secondary,
            layout: EmptyStateLayout.compact,
            primaryActionLabel: 'Add Subscription',
            primaryActionIcon: Icons.add_rounded,
            onPrimaryAction: onAddSubscription,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                SubscriptionCard(
                  item: items[i],
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
