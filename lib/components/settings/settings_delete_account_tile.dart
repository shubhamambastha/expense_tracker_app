import 'package:flutter/material.dart';

import '../dialogs/confirm_delete_account_dialog.dart';
import '../../config/design_tokens.dart';
import 'settings_tile.dart';

/// Destructive delete-account row with typed confirmation.
class SettingsDeleteAccountTile extends StatelessWidget {
  const SettingsDeleteAccountTile({
    super.key,
    required this.onDeleteConfirmed,
  });

  final VoidCallback onDeleteConfirmed;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: Icons.delete_forever_rounded,
      title: 'Delete Account',
      subtitle: 'Permanently remove your account and data',
      destructive: true,
      onTap: () => _confirmDelete(context),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDeleteAccountDialog(context);
    if (confirmed) {
      onDeleteConfirmed();
    }
  }
}

/// Danger-tinted card wrapper for account deletion inside sub-pages.
class SettingsDeleteAccountSection extends StatelessWidget {
  const SettingsDeleteAccountSection({
    super.key,
    required this.onDeleteConfirmed,
  });

  final VoidCallback onDeleteConfirmed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            0,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Text(
            'ACCOUNT',
            style: AppTextStyles.label.copyWith(
              color: AppColors.danger,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.danger.withAlpha(70)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SettingsDeleteAccountTile(
            onDeleteConfirmed: onDeleteConfirmed,
          ),
        ),
      ],
    );
  }
}
