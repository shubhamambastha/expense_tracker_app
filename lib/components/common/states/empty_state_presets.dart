import 'package:flutter/material.dart';

import 'empty_state.dart';
import 'state_icon_badge.dart';

/// Product-ready empty states with consistent copy and CTAs.
abstract final class EmptyStatePresets {
  EmptyStatePresets._();

  static Widget noTransactions({required VoidCallback onAddTransaction}) {
    return EmptyState(
      icon: Icons.receipt_long_rounded,
      title: 'No transactions yet',
      subtitle: 'Start tracking your spending to unlock insights.',
      primaryActionLabel: 'Add Transaction',
      primaryActionIcon: Icons.add_rounded,
      onPrimaryAction: onAddTransaction,
    );
  }

  static Widget noAccounts({required VoidCallback onAddAccount}) {
    return EmptyState(
      icon: Icons.account_balance_wallet_rounded,
      title: 'No accounts added',
      subtitle: 'Add a bank account, card, or wallet to start tracking money.',
      primaryActionLabel: 'Add Account',
      primaryActionIcon: Icons.add_rounded,
      onPrimaryAction: onAddAccount,
    );
  }

  static Widget noBudgets({required VoidCallback onCreateBudget}) {
    return EmptyState(
      icon: Icons.donut_small_rounded,
      iconTone: StateBadgeTone.secondary,
      title: 'No budgets created',
      subtitle: 'Set spending limits to control your finances better.',
      primaryActionLabel: 'Create Budget',
      primaryActionIcon: Icons.flag_rounded,
      onPrimaryAction: onCreateBudget,
    );
  }

  static Widget noAnalyticsData({required VoidCallback onAddTransaction}) {
    return EmptyState(
      icon: Icons.insights_rounded,
      title: 'Not enough data yet',
      subtitle:
          'Track more transactions to unlock analytics and insights.',
      primaryActionLabel: 'Add Transaction',
      primaryActionIcon: Icons.add_rounded,
      onPrimaryAction: onAddTransaction,
    );
  }

  static Widget noSubscriptions({required VoidCallback onAddSubscription}) {
    return EmptyState(
      icon: Icons.event_repeat_rounded,
      iconTone: StateBadgeTone.secondary,
      title: 'No subscriptions tracked',
      subtitle:
          'Track recurring services like Netflix, Spotify, and more.',
      primaryActionLabel: 'Add Subscription',
      primaryActionIcon: Icons.add_rounded,
      onPrimaryAction: onAddSubscription,
    );
  }

  static Widget noSearchResults({required VoidCallback onClearFilters}) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      iconTone: StateBadgeTone.neutral,
      title: 'No matching transactions found',
      subtitle: 'Try changing filters or searching different keywords.',
      primaryActionLabel: 'Clear Filters',
      onPrimaryAction: onClearFilters,
      layout: EmptyStateLayout.compact,
    );
  }
}
