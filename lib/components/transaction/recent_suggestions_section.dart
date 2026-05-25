import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/transaction_draft.dart';
import '../../services/category_catalog.dart';
import '../../utils/category_style.dart';

/// Lightweight "Recent / Frequent" autofill row.
///
/// Tapping a suggestion fires [onTap] with the full [RecentSuggestion] so the
/// parent screen can autofill merchant, category and account in one go.
/// Intentionally small — never crowd the primary input flow.
class RecentSuggestionsSection extends StatelessWidget {
  const RecentSuggestionsSection({
    super.key,
    required this.suggestions,
    required this.onTap,
    this.title = 'Recent',
    this.showCategoryPrefix = false,
  });

  final List<RecentSuggestion> suggestions;
  final ValueChanged<RecentSuggestion> onTap;
  final String title;

  /// When true, pills show "Category · Payer" (income autofill format).
  final bool showCategoryPrefix;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.label,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return _SuggestionPill(
                suggestion: suggestion,
                showCategoryPrefix: showCategoryPrefix,
                onTap: () => onTap(suggestion),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({
    required this.suggestion,
    required this.onTap,
    this.showCategoryPrefix = false,
  });

  final RecentSuggestion suggestion;
  final VoidCallback onTap;
  final bool showCategoryPrefix;

  @override
  Widget build(BuildContext context) {
    final catalog = CategoryCatalog.instance;
    final color = catalog.colorForName(suggestion.category);
    final iconKey =
        catalog.findByName(suggestion.category)?.iconKey ?? CategoryIcons.defaultKey;

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CategoryIcons.iconForKey(iconKey),
                size: 12,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              showCategoryPrefix
                  ? '${suggestion.category} · ${suggestion.merchant}'
                  : suggestion.merchant,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
