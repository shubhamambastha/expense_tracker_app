import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import 'settings_tile.dart';

/// Bottom danger zone with Sign Out.
///
/// Wrapped in a danger-tinted card so it visually separates from the rest
/// of the Settings screen.
class SettingsDangerSection extends StatelessWidget {
  const SettingsDangerSection({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

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
                title: 'Sign Out',
                subtitle: 'End this session on this device',
                destructive: true,
                onTap: () => _confirmLogout(context),
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
        title: const Text('Sign Out'),
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onLogout();
    }
  }
}
