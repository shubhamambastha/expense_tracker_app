import 'package:flutter/material.dart';

import '../../../../config/design_tokens.dart';

class ActionsSection extends StatelessWidget {
  const ActionsSection({
    super.key,
    required this.isRecurring,
    required this.onEdit,
    required this.onDuplicate,
    required this.onConvertToRecurring,
    required this.onDelete,
  });

  final bool isRecurring;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onConvertToRecurring;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDuplicate,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Duplicate'),
              ),
            ),
          ],
        ),
        if (!isRecurring) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onConvertToRecurring,
            icon: const Icon(Icons.autorenew_rounded, size: 18),
            label: const Text('Convert to Recurring'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: onDelete,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.textPrimary,
          ),
          icon: const Icon(Icons.delete_rounded, size: 18),
          label: const Text('Delete Transaction'),
        ),
      ],
    );
  }
}
