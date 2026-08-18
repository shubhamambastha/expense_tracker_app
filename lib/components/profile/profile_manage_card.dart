import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Compact profile card with See all / Add actions (no inline list).
class ProfileManageCard extends StatelessWidget {
  const ProfileManageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSeeAll,
    required this.onAdd,
    this.seeAllLabel = 'See all',
    this.addLabel = 'Add',
  });

  final String title;
  final String subtitle;
  final VoidCallback onSeeAll;
  final VoidCallback onAdd;
  final String seeAllLabel;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSeeAll,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.list_rounded, size: 18),
                  label: Text(seeAllLabel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(addLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
