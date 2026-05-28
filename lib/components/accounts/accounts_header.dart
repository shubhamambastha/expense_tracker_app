import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../utils/account_management.dart';

/// Header for the Accounts list screen with optional sort/manage action.
class AccountsHeader extends StatelessWidget {
  const AccountsHeader({
    super.key,
    required this.accountCount,
    this.onManageTap,
  });

  final int accountCount;
  final VoidCallback? onManageTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accounts', style: AppTextStyles.headingMedium),
              const SizedBox(height: 2),
              Text(
                accountCount == 0
                    ? 'Add your money sources to get started'
                    : '$accountCount linked source${accountCount == 1 ? '' : 's'}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        if (onManageTap != null)
          IconButton(
            onPressed: onManageTap,
            tooltip: 'Sort & manage',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 20),
          ),
      ],
    );
  }
}

/// Sort/manage bottom sheet for the accounts list.
Future<AccountSortMode?> showAccountsManageSheet(
  BuildContext context, {
  required AccountSortMode currentSort,
  required bool showArchived,
}) {
  return showModalBottomSheet<AccountSortMode>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Sort accounts', style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSpacing.md),
              _SortOption(
                label: 'Name',
                selected: currentSort == AccountSortMode.name,
                onTap: () =>
                    Navigator.of(sheetContext).pop(AccountSortMode.name),
              ),
              _SortOption(
                label: 'Balance',
                selected: currentSort == AccountSortMode.balance,
                onTap: () =>
                    Navigator.of(sheetContext).pop(AccountSortMode.balance),
              ),
              _SortOption(
                label: 'Type',
                selected: currentSort == AccountSortMode.type,
                onTap: () =>
                    Navigator.of(sheetContext).pop(AccountSortMode.type),
              ),
              if (showArchived) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Archived accounts are hidden from the list.',
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
