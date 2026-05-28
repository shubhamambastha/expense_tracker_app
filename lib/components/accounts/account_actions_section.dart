import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../transaction/detail/widgets/detail_section_card.dart';

/// Action rows for account detail screens.
class AccountActionsSection extends StatelessWidget {
  const AccountActionsSection({
    super.key,
    required this.onEdit,
    required this.onArchive,
    this.onSetDefault,
    this.onAddTransaction,
    this.isDefault = false,
  });

  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback? onSetDefault;
  final VoidCallback? onAddTransaction;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      title: 'Actions',
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.edit_rounded,
            label: 'Edit account',
            onTap: onEdit,
          ),
          if (onAddTransaction != null)
            _ActionRow(
              icon: Icons.add_rounded,
              label: 'Add transaction',
              onTap: onAddTransaction!,
            ),
          if (onSetDefault != null && !isDefault)
            _ActionRow(
              icon: Icons.star_rounded,
              label: 'Set as default',
              onTap: onSetDefault!,
            ),
          _ActionRow(
            icon: Icons.archive_rounded,
            label: 'Archive account',
            tone: AppColors.warning,
            onTap: onArchive,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: color),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
