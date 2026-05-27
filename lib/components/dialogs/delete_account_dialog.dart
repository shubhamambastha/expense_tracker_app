import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Typed-confirmation dialog before permanently deleting an account.
Future<bool> showDeleteAccountConfirmation(BuildContext context) async {
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
    return confirmed == true;
  } finally {
    controller.dispose();
  }
}
