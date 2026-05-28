import 'package:flutter/material.dart';

import '../common/states/empty_state.dart';
import '../common/states/empty_state_presets.dart';

/// Full-screen empty state for the accounts list.
class AccountsEmptyState extends StatelessWidget {
  const AccountsEmptyState({super.key, required this.onAddAccount});

  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    return EmptyStatePresets.noAccounts(onAddAccount: onAddAccount);
  }
}

/// Compact empty state for a section (e.g. no credit cards).
class AccountsSectionEmptyState extends StatelessWidget {
  const AccountsSectionEmptyState({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title,
      primaryActionLabel: actionLabel,
      onPrimaryAction: onAction,
      layout: EmptyStateLayout.compact,
    );
  }
}
