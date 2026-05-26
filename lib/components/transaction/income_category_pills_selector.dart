import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/income_category.dart';
import '../../services/income_category_catalog.dart';
import '../../utils/category_style.dart';

/// Horizontal income category chips (Salary, Freelance, Refund, …).
///
/// Mirrors [CategoryPillsSelector] but reads from [IncomeCategoryCatalog] so
/// expense categories never leak into income mode.
class IncomeCategoryPillsSelector extends StatelessWidget {
  const IncomeCategoryPillsSelector({
    super.key,
    required this.selectedName,
    required this.onChanged,
    this.prioritisedNames = const [],
  });

  final String? selectedName;
  final ValueChanged<String> onChanged;
  final List<String> prioritisedNames;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: IncomeCategoryCatalog.instance,
      builder: (context, _) {
        final catalog = IncomeCategoryCatalog.instance;
        final categories = _ordered(catalog.categories);

        if (categories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Add income categories in Settings to organise entries.',
              style: AppTextStyles.caption,
            ),
          );
        }

        return SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = catalog.colorForName(category.name);
              return _IncomeCategoryPill(
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

  List<IncomeCategory> _ordered(List<IncomeCategory> all) {
    if (prioritisedNames.isEmpty) return all;
    final byName = {for (final c in all) c.name: c};
    final ordered = <IncomeCategory>[];
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

class _IncomeCategoryPill extends StatelessWidget {
  const _IncomeCategoryPill({
    required this.category,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IncomeCategory category;
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
