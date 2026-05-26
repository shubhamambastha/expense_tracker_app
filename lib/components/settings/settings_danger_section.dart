import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import 'settings_tile.dart';

/// Bottom danger zone with Logout + Delete Account.
///
/// Wrapped in a danger-tinted card so it visually separates from the rest
/// of the Settings screen. Delete Account opens a typed-confirmation
/// dialog (matches premium destructive-action UX) before invoking the
/// caller-supplied callback.
class SettingsDangerSection extends StatelessWidget {
  const SettingsDangerSection({
    super.key,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'End this session on this device',
                destructive: true,
                onTap: () => _confirmLogout(context),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
              ),
              SettingsTile(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently remove your account and data',
                destructive: true,
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'You will need to sign in again to access your finances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onLogout();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final controller = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final canConfirm =
                  controller.text.trim().toUpperCase() == 'DELETE';

              return AlertDialog(
                title: const Text('Delete account'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This permanently removes your account, transactions, '
                      'accounts, and preferences. This cannot be undone.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Type DELETE to confirm:',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'DELETE',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: canConfirm
                        ? () => Navigator.of(dialogContext).pop(true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Delete forever'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed == true) {
        onDeleteAccount();
      }
    } finally {
      controller.dispose();
    }
  }
}
