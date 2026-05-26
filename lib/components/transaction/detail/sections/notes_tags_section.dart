import 'package:flutter/material.dart';

import '../../../../config/design_tokens.dart';
import '../transaction_detail_view_data.dart';
import '../widgets/detail_section_card.dart';

class NotesTagsSection extends StatelessWidget {
  const NotesTagsSection({super.key, required this.data});

  final TransactionDetailViewData data;

  @override
  Widget build(BuildContext context) {
    if (!data.showNotesSection) return const SizedBox.shrink();

    return DetailSectionCard(
      title: 'Notes & Tags',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.hasNote) ...[
            Text(
              data.tx.note!.trim(),
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
              ),
            ),
          ],
          if (data.hasTags) ...[
            if (data.hasNote) const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in data.tags)
                  _TagChip(label: tag.startsWith('#') ? tag : '#$tag'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
