import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Typed-confirmation dialog for wiping all of the user's data.
Future<bool> showConfirmResetAccountDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const _ConfirmResetAccountDialog(),
  );
  return confirmed == true;
}

class _ConfirmResetAccountDialog extends StatefulWidget {
  const _ConfirmResetAccountDialog();

  @override
  State<_ConfirmResetAccountDialog> createState() =>
      _ConfirmResetAccountDialogState();
}

class _ConfirmResetAccountDialogState
    extends State<_ConfirmResetAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _controller.text.trim().toUpperCase() == 'RESET';

    return AlertDialog(
      title: const Text('Reset my account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This permanently erases your transactions, accounts, '
            'categories, budgets, and recurring payments. Your '
            'login and preferences are kept. This cannot be undone.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Type RESET to confirm:',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'RESET',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.textPrimary,
          ),
          child: const Text('Reset account'),
        ),
      ],
    );
  }
}
