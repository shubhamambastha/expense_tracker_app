import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/expense_category.dart';
import '../../services/category_catalog.dart';
import '../../utils/category_style.dart';

/// Horizontal scrollable category chips.
///
/// Optimised for *single-tap* selection — no bottom sheet, no extra screen.
/// Recently-used categories bubble to the front via [prioritisedNames] so
/// frequent picks land under the thumb without any scrolling at all.
class CategoryPillsSelector extends StatelessWidget {
  const CategoryPillsSelector({
    super.key,
    required this.selectedName,
    required this.onChanged,
    this.prioritisedNames = const [],
    this.onSeeAll,
  });

  final String? selectedName;
  final ValueChanged<String> onChanged;

  /// Names that should appear first in the scroll list (recent / frequent).
  final List<String> prioritisedNames;

  /// Optional "See all" action — useful when the catalog grows large.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final catalog = CategoryCatalog.instance;
    return ListenableBuilder(
      listenable: catalog,
      builder: (context, _) {
        final categories = _ordered(catalog.categories);
        if (categories.isEmpty) {
          return _EmptyHint(onSeeAll: onSeeAll);
        }

        return SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: categories.length + (onSeeAll != null ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == categories.length) {
                return _SeeAllPill(onTap: onSeeAll!);
              }
              final category = categories[index];
              final color = catalog.colorForName(category.name);
              return _CategoryPill(
                category: category,
                color: color,
                selected: category.name == selectedName,
                onTap: () => onChanged(category.name),
              );
            },
          ),
        );
      },
    );
  }

  List<ExpenseCategory> _ordered(List<ExpenseCategory> all) {
    if (prioritisedNames.isEmpty) return all;
    final byName = {for (final c in all) c.name: c};
    final ordered = <ExpenseCategory>[];
    final seen = <String>{};
    for (final name in prioritisedNames) {
      final c = byName[name];
      if (c != null && seen.add(name)) ordered.add(c);
    }
    for (final c in all) {
      if (seen.add(c.name)) ordered.add(c);
    }
    return ordered;
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.category,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.chipRadius,
      child: AnimatedContainer(
        duration: AppDurations.micro,
        curve: AppCurves.spring,
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(32) : AppColors.surfaceSecondary,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(
            color: selected ? color.withAlpha(140) : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(selected ? 48 : 28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CategoryIcons.iconForKey(category.iconKey),
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? color : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeeAllPill extends StatelessWidget {
  const _SeeAllPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.chipRadius,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'See all',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({this.onSeeAll});

  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Add categories in Settings to organise your spending.',
                style: AppTextStyles.caption,
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text('Manage'),
              ),
          ],
        ),
      ),
    );
  }
}
