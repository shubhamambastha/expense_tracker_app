import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/recurring_management.dart';
import '../common/states/empty_state.dart';
import '../common/states/state_icon_badge.dart';
import '../home/dashboard/dashboard_section_header.dart';
import 'emi_card.dart';
import 'upcoming_timeline_section.dart';

/// Lists active EMIs (home loan, car, gadget, credit-card EMIs).
///
/// Each item renders an [EmiCard] with a progress strip. Inline empty state
/// when no EMIs exist.
class EmiManagementSection extends StatelessWidget {
  const EmiManagementSection({
    super.key,
    required this.items,
    required this.monthlyTotal,
    required this.onTapItem,
    required this.onAction,
    required this.onAddEmi,
  });

  final List<RecurringScheduleItem> items;
  final double monthlyTotal;
  final void Function(RecurringScheduleItem item) onTapItem;
  final void Function(
    RecurringQuickAction action,
    RecurringScheduleItem item,
  ) onAction;
  final VoidCallback onAddEmi;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'EMI Management',
          subtitle: items.isEmpty
              ? null
              : '${items.length} open · ${currency.formatCompact(monthlyTotal)} '
                  'per month',
          actionLabel: items.isEmpty ? null : 'Add',
          onActionTap: items.isEmpty ? null : onAddEmi,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          EmptyState(
            title: 'No EMIs active',
            subtitle:
                'Add a home, car, or gadget EMI to track tenure and monthly '
                'outflow side-by-side.',
            icon: Icons.receipt_long_rounded,
            iconTone: StateBadgeTone.warning,
            layout: EmptyStateLayout.compact,
            primaryActionLabel: 'Add EMI',
            primaryActionIcon: Icons.add_rounded,
            onPrimaryAction: onAddEmi,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                EmiCard(
                  item: items[i],
                  progress: RecurringManagement.emiProgress(
                    items[i].transaction,
                  ),
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
