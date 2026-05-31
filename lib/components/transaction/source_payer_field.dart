import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Source / payer input for income mode with dynamic label and quick picks.
///
/// Lives outside [TransactionDetailsCard] so income entry stays lightweight:
/// amount → category → deposit account → payer → details.
class SourcePayerField extends StatelessWidget {
  const SourcePayerField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    this.recentPayers = const [],
    this.onPayerSelected,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> recentPayers;
  final ValueChanged<String>? onPayerSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(28),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => focusNode.unfocus(),
                      onEditingComplete: () => focusNode.unfocus(),
                      onTapOutside: (_) => focusNode.unfocus(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: hintText,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (recentPayers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recentPayers.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final payer = recentPayers[index];
                  return _PayerChip(
                    label: payer,
                    onTap: () => onPayerSelected?.call(payer),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayerChip extends StatelessWidget {
  const _PayerChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.pillRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: AppRadii.pillRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
