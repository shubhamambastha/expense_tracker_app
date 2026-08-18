import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../utils/recurring_management.dart';
import '../home/dashboard/dashboard_section_header.dart';
import 'upcoming_payment_tile.dart';

/// Quick actions surfaced from the timeline, subscription card, EMI card,
/// and recurring expense card. Not every surface offers every action — the
/// timeline overflow stays focused on per-occurrence actions
/// (Snooze · Pause), while the schedule cards add `close` for permanent
/// termination (cancel subscription / mark EMI completed / close schedule).
enum RecurringQuickAction { markPaid, skip, snooze, pause, close }

/// The most important section on the manager screen.
///
/// Renders the upcoming payments grouped by [UpcomingBucket] (Today /
/// Tomorrow / This Week / Later This Month). Each tile is wrapped in a
/// `Dismissible` so users can:
/// * swipe right (start → end) → Mark paid
/// * swipe left  (end → start) → Skip next
/// * tap the trailing menu     → Snooze 3 days · Pause schedule
class UpcomingTimelineSection extends StatelessWidget {
  const UpcomingTimelineSection({
    super.key,
    required this.snapshot,
    required this.onTapItem,
    required this.onAction,
  });

  final RecurringManagementSnapshot snapshot;
  final void Function(UpcomingPaymentItem item) onTapItem;
  final void Function(RecurringQuickAction action, UpcomingPaymentItem item)
      onAction;

  @override
  Widget build(BuildContext context) {
    final byBucket = snapshot.upcomingByBucket;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Upcoming Payments',
          subtitle: snapshot.upcoming.isEmpty
              ? 'No payments due in the next 30 days.'
              : 'Swipe to mark paid or skip · tap for more.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (snapshot.upcoming.isEmpty)
          const _EmptyTimelineCard()
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: AppRadii.cardRadius,
              child: Column(
                children: [
                  for (var i = 0; i < UpcomingBucket.values.length; i++)
                    if ((byBucket[UpcomingBucket.values[i]] ?? const [])
                        .isNotEmpty) ...[
                      if (i != 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                      _BucketGroup(
                        bucket: UpcomingBucket.values[i],
                        items: byBucket[UpcomingBucket.values[i]]!,
                        onTapItem: onTapItem,
                        onAction: onAction,
                      ),
                    ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BucketGroup extends StatelessWidget {
  const _BucketGroup({
    required this.bucket,
    required this.items,
    required this.onTapItem,
    required this.onAction,
  });

  final UpcomingBucket bucket;
  final List<UpcomingPaymentItem> items;
  final void Function(UpcomingPaymentItem item) onTapItem;
  final void Function(RecurringQuickAction action, UpcomingPaymentItem item)
      onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BucketHeader(label: bucket.label, count: items.length),
        for (var i = 0; i < items.length; i++) ...[
          _SwipeableTile(
            item: items[i],
            onTap: () => onTapItem(items[i]),
            onAction: (action) => onAction(action, items[i]),
          ),
          if (i != items.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
              indent: AppSpacing.lg,
              endIndent: AppSpacing.lg,
            ),
        ],
      ],
    );
  }
}

class _BucketHeader extends StatelessWidget {
  const _BucketHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      color: AppColors.surfaceSecondary,
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            count == 1 ? '1 payment' : '$count payments',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _SwipeableTile extends StatelessWidget {
  const _SwipeableTile({
    required this.item,
    required this.onTap,
    required this.onAction,
  });

  final UpcomingPaymentItem item;
  final VoidCallback onTap;
  final void Function(RecurringQuickAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(
        'upcoming-${item.transaction.id ?? item.transaction.counterpartyName}-'
        '${item.dueDate.toIso8601String()}',
      ),
      background: const _SwipeBackground(
        color: AppColors.success,
        alignment: Alignment.centerLeft,
        icon: Icons.check_circle_rounded,
        label: 'Mark paid',
      ),
      secondaryBackground: const _SwipeBackground(
        color: AppColors.warning,
        alignment: Alignment.centerRight,
        icon: Icons.skip_next_rounded,
        label: 'Skip',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onAction(RecurringQuickAction.markPaid);
        } else if (direction == DismissDirection.endToStart) {
          onAction(RecurringQuickAction.skip);
        }
        // We let the parent rebuild the list (events change → snapshot
        // re-derives), so the tile shouldn't permanently leave the tree on
        // its own.
        return false;
      },
      child: UpcomingPaymentTile(
        item: item,
        onTap: onTap,
        trailingMenu: _OverflowMenu(onSelect: onAction),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.onSelect});

  final void Function(RecurringQuickAction action) onSelect;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RecurringQuickAction>(
      tooltip: 'More actions',
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
      color: AppColors.surfaceSecondary,
      onSelected: onSelect,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: RecurringQuickAction.snooze,
          child: _MenuRow(
            icon: Icons.snooze_rounded,
            label: 'Snooze 3 days',
          ),
        ),
        PopupMenuItem(
          value: RecurringQuickAction.pause,
          child: _MenuRow(
            icon: Icons.pause_circle_rounded,
            label: 'Pause schedule',
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textPrimary),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.alignment,
    required this.icon,
    required this.label,
  });

  final Color color;
  final Alignment alignment;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withAlpha(36),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: alignment,
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimelineCard extends StatelessWidget {
  const _EmptyTimelineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No payments due soon — you\'re all caught up.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
