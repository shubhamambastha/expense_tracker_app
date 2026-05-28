import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../home/dashboard/dashboard_section_header.dart';
import '../common/states/empty_state.dart';

/// Section wrapper for grouped account lists.
class AccountsSection extends StatelessWidget {
  const AccountsSection({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    required this.children,
    this.emptyTitle,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final List<Widget> children;
  final String? emptyTitle;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    final isEmpty = children.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: title,
          subtitle: subtitle,
          actionLabel: actionLabel,
          onActionTap: onActionTap,
        ),
        const SizedBox(height: AppSpacing.md),
        if (isEmpty && emptyTitle != null)
          EmptyState(
            title: emptyTitle!,
            primaryActionLabel: emptyActionLabel,
            onPrimaryAction: onEmptyAction,
            layout: EmptyStateLayout.compact,
          )
        else
          ...children,
      ],
    );
  }
}
