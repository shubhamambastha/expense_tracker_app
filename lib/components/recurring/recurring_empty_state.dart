import 'package:flutter/material.dart';

import '../common/states/empty_state.dart';
import '../common/states/state_icon_badge.dart';

/// Full-screen empty state shown when the user has zero recurring
/// transactions of any kind.
///
/// The per-section ("No subscriptions tracked", "No EMIs active") empty
/// states are handled inline by each section so users can still see the
/// scaffold (header + insights) when only one bucket is empty.
class RecurringEmptyState extends StatelessWidget {
  const RecurringEmptyState({super.key, required this.onAddRecurring});

  final VoidCallback onAddRecurring;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No recurring payments yet',
      subtitle:
          'Track subscriptions, EMIs, and bills to stay ahead of upcoming '
          'payments.',
      icon: Icons.event_repeat_rounded,
      iconTone: StateBadgeTone.primary,
      primaryActionLabel: 'Add Recurring Payment',
      primaryActionIcon: Icons.add_rounded,
      onPrimaryAction: onAddRecurring,
    );
  }
}
