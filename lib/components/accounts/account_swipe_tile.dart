import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

enum AccountSwipeAction { edit, archive }

/// Swipeable wrapper: swipe right to edit, swipe left to archive.
class AccountSwipeTile extends StatelessWidget {
  const AccountSwipeTile({
    super.key,
    required this.dismissKey,
    required this.child,
    required this.onAction,
  });

  final Key dismissKey;
  final Widget child;
  final void Function(AccountSwipeAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: dismissKey,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onAction(AccountSwipeAction.edit);
        } else {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Archive account?'),
              content: const Text(
                'This account will be hidden from your list. '
                'Your transactions will stay intact.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Archive'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            onAction(AccountSwipeAction.archive);
          }
        }
        return false;
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.primary.withAlpha(40),
        icon: Icons.edit_rounded,
        label: 'Edit',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.warning.withAlpha(40),
        icon: Icons.archive_rounded,
        label: 'Archive',
      ),
      child: child,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadii.cardRadius,
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.bodyMedium),
          ] else ...[
            Text(label, style: AppTextStyles.bodyMedium),
            const SizedBox(width: AppSpacing.sm),
            Icon(icon, size: 20),
          ],
        ],
      ),
    );
  }
}
