import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/expense_category.dart';
import '../../services/category_catalog.dart';
import '../../utils/snackbar_helper.dart';
import '../dialogs/add_category_sheet.dart';
import '../profile/profile_manage_card.dart';
import 'category_list_row.dart';

/// Settings section for managing expense categories.
class ExpenseCategoriesSection extends StatelessWidget {
  const ExpenseCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CategoryCatalog.instance,
      builder: (context, _) {
        final catalog = CategoryCatalog.instance;
        final count = catalog.categories.length;
        final subtitle = count == 0
            ? 'No categories yet'
            : count == 1
                ? '1 category'
                : '$count categories';

        return ProfileManageCard(
          title: 'Expense categories',
          subtitle: subtitle,
          seeAllLabel: 'See all',
          addLabel: 'Add',
          onSeeAll: () => _openAllCategoriesSheet(context),
          onAdd: () => _openAddCategorySheet(context),
        );
      },
    );
  }

  Future<void> _openAddCategorySheet(BuildContext context) async {
    final added = await showAddCategorySheet(
      context,
      title: 'New expense category',
      onSave: (name, iconKey) => CategoryCatalog.instance.addCategory(
        name: name,
        iconKey: iconKey,
      ),
    );

    if (added == true && context.mounted) {
      SnackbarHelper.showSuccess(context, 'Expense category added');
    }
  }

  Future<void> _openAllCategoriesSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;

        return ListenableBuilder(
          listenable: CategoryCatalog.instance,
          builder: (context, _) {
            final categories = CategoryCatalog.instance.categories;

            return SafeArea(
              child: SizedBox(
                height: maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xs,
                        AppSpacing.xl,
                        AppSpacing.xs,
                      ),
                      child: Text(
                        'Expense categories',
                        style: AppTextStyles.headingSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Text(
                        'Default categories cannot be removed.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: categories.isEmpty
                          ? Center(
                              child: Text(
                                'No categories yet. Tap Add above.',
                                style: AppTextStyles.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              itemCount: categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final catalog = CategoryCatalog.instance;
                                return CategoryListRow(
                                  name: category.name,
                                  color: catalog.colorForName(category.name),
                                  icon: catalog.iconForName(category.name),
                                  isDefault: category.isDefault,
                                  onDelete: category.isDefault
                                      ? null
                                      : () => _confirmDelete(
                                            context,
                                            sheetContext,
                                            category,
                                          ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BuildContext sheetContext,
    ExpenseCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category'),
        content: Text(
          'Remove "${category.name}"? Transactions already using it will keep the label.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await CategoryCatalog.instance.deleteCategory(category);
      if (sheetContext.mounted && CategoryCatalog.instance.categories.isEmpty) {
        Navigator.of(sheetContext).pop();
      }
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'Category removed');
      }
    } catch (error) {
      if (context.mounted) {
        SnackbarHelper.showMessage(context, error.toString());
      }
    }
  }
}
